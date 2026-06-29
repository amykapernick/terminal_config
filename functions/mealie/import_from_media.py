#!/usr/bin/env python3
"""
Recipe Photo → Mealie Importer
================================
Reads a folder of recipe photos, uses Azure OpenAI's vision API to extract
recipe(s) from each image, and imports them into Mealie.

Handles multiple recipes per photo automatically.

Requirements:
    pip install requests

Setup:
    AZURE_OPENAI_API_KEY    – Azure OpenAI API key (Azure portal → your OpenAI resource → Keys)
    AZURE_OPENAI_ENDPOINT   – Azure OpenAI endpoint e.g. https://my-resource.openai.azure.com
    AZURE_OPENAI_DEPLOYMENT – Name of your GPT-4o deployment e.g. gpt-4o
    MEALIE_URL              – Base URL of your Mealie instance e.g. http://localhost:9000
    MEALIE_TOKEN            – Mealie API token (Profile → API Tokens)

Usage:
    python3 photos_to_mealie.py ~/recipes/photos
    python3 photos_to_mealie.py ~/recipes/photos --dry-run
"""

import argparse
import os
import re
import shutil
import sys
import time
import uuid
import json
import base64
import hashlib
import logging
import mimetypes
import subprocess
import tempfile
from pathlib import Path
from typing import Optional

import requests
from dotenv import load_dotenv

load_dotenv(Path.home() / ".env")

# ── Configuration ──────────────────────────────────────────────────────────────

AZURE_OPENAI_API_KEY    = os.environ.get("AZURE_OPENAI_API_KEY", "")
AZURE_OPENAI_ENDPOINT   = os.environ.get("AZURE_OPENAI_ENDPOINT", "").rstrip("/")
AZURE_OPENAI_DEPLOYMENT = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4o")
AZURE_OPENAI_API_VERSION = "2024-02-01"

MEALIE_URL   = os.environ.get("MEALIE_URL", "http://localhost:9000").rstrip("/")
MEALIE_TOKEN = os.environ.get("MEALIE_TOKEN", "YOUR_MEALIE_TOKEN")

SUPPORTED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
SUPPORTED_VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv", ".m4v", ".webm"}
SUPPORTED_EXTENSIONS       = SUPPORTED_IMAGE_EXTENSIONS | SUPPORTED_VIDEO_EXTENSIONS

# How often to extract a frame from video (seconds). Lower = more frames = slower + more API calls.
VIDEO_FRAME_INTERVAL = float(os.environ.get("VIDEO_FRAME_INTERVAL", "2"))

# Videos longer than this (seconds) are split into chunks before processing.
VIDEO_SPLIT_THRESHOLD = float(os.environ.get("VIDEO_SPLIT_THRESHOLD", "300"))  # 5 minutes

# Max number of files to process per run. 0 = process all.
PROCESS_LIMIT = 0

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ── Mealie API ─────────────────────────────────────────────────────────────────

MEALIE_HEADERS = {
    "Authorization": f"Bearer {MEALIE_TOKEN}",
    "Content-Type": "application/json",
}


def mealie_get_tags() -> dict[str, dict]:
    resp = requests.get(f"{MEALIE_URL}/api/organizers/tags?perPage=500",
                        headers=MEALIE_HEADERS, timeout=15)
    resp.raise_for_status()
    return {
        t["name"].lower(): {"id": t["id"], "slug": t["slug"], "name": t["name"]}
        for t in resp.json().get("items", [])
    }


def mealie_create_tag(name: str) -> Optional[dict]:
    resp = requests.post(f"{MEALIE_URL}/api/organizers/tags",
                         headers=MEALIE_HEADERS,
                         json={"name": name}, timeout=15)
    if resp.status_code in (200, 201):
        t = resp.json()
        return {"id": t["id"], "slug": t["slug"], "name": t["name"]}
    # Mealie can return 409 or 500 when a tag already exists — search for it
    search = requests.get(f"{MEALIE_URL}/api/organizers/tags",
                          headers=MEALIE_HEADERS,
                          params={"search": name, "perPage": 10}, timeout=15)
    if search.status_code == 200:
        for t in search.json().get("items", []):
            if t["name"].lower() == name.lower():
                log.info("  Found existing tag: %s", name)
                return {"id": t["id"], "slug": t["slug"], "name": t["name"]}
    log.warning("Could not create tag '%s': %s", name, resp.text)
    return None


def mealie_ensure_tags(names: list[str], cache: dict) -> list[dict]:
    result = []
    for name in names:
        key = name.strip().lower()
        if not key:
            continue
        tag_info = cache.get(key)
        if not tag_info:
            log.info("  Creating new tag: %s", name.strip())
            tag_info = mealie_create_tag(name.strip())
            if tag_info:
                cache[key] = tag_info
        if tag_info:
            result.append(tag_info)
    return result


def mealie_create_recipe(name: str) -> tuple[Optional[str], bool]:
    """Returns (slug, is_duplicate). slug is None on failure."""
    for attempt in range(2):
        try:
            resp = requests.post(f"{MEALIE_URL}/api/recipes",
                                 headers=MEALIE_HEADERS,
                                 json={"name": name}, timeout=30)
            break
        except requests.exceptions.RequestException as e:
            if attempt == 0:
                log.warning("Network error creating recipe '%s': %s — retrying in 60s", name, e)
                time.sleep(60)
            else:
                log.error("Network error creating recipe '%s': %s", name, e)
                return None, False
    if resp.status_code in (200, 201):
        slug = resp.json()
        return (slug if isinstance(slug, str) else slug.get("slug")), False
    if resp.status_code == 409:
        log.info("  Recipe '%s' already exists in Mealie, skipping.", name)
        return None, True
    log.error("Failed to create recipe '%s': %s %s", name, resp.status_code, resp.text)
    return None, False


def mealie_delete_recipe(slug: str) -> None:
    resp = requests.delete(f"{MEALIE_URL}/api/recipes/{slug}",
                           headers=MEALIE_HEADERS, timeout=15)
    if resp.status_code not in (200, 204):
        log.warning("  Could not delete empty recipe shell '%s': %s", slug, resp.status_code)


def mealie_update_recipe(slug: str, payload: dict) -> tuple[bool, bool]:
    """Returns (success, is_duplicate)."""
    for attempt in range(2):
        try:
            resp = requests.patch(f"{MEALIE_URL}/api/recipes/{slug}",
                                  headers=MEALIE_HEADERS,
                                  json=payload, timeout=30)
            break
        except requests.exceptions.RequestException as e:
            if attempt == 0:
                log.warning("Network error updating recipe '%s': %s — retrying in 60s", slug, e)
                time.sleep(60)
            else:
                log.error("Network error updating recipe '%s': %s", slug, e)
                return False, False
    if resp.status_code in (200, 201):
        return True, False
    if resp.status_code == 400:
        try:
            detail = resp.json().get("detail", {})
            msg = detail.get("message", "") if isinstance(detail, dict) else str(detail)
            if "already exists" in msg.lower():
                return False, True
        except Exception:
            pass
    log.error("Failed to update '%s': %s %s", slug, resp.status_code, resp.text)
    return False, False


def mealie_upload_image(recipe_slug: str, image_path: Path) -> bool:
    content_type = mimetypes.guess_type(str(image_path))[0] or "image/jpeg"
    upload_headers = {"Authorization": f"Bearer {MEALIE_TOKEN}"}
    try:
        with open(image_path, "rb") as f:
            resp = requests.put(
                f"{MEALIE_URL}/api/recipes/{recipe_slug}/image",
                headers=upload_headers,
                files={"image": (image_path.name, f, content_type)},
                timeout=30,
            )
        if resp.status_code in (200, 201):
            log.info("  ✓ Image uploaded.")
            return True
        log.warning("  Image upload failed: %s %s", resp.status_code, resp.text)
    except Exception as e:
        log.warning("  Image upload error: %s", e)
    return False


# ── Video frame extraction ─────────────────────────────────────────────────────

def check_ffmpeg() -> bool:
    """Return True if ffmpeg is available on PATH."""
    try:
        subprocess.run(["ffmpeg", "-version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def get_video_duration(video_path: Path) -> float:
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
         "-of", "csv=p=0", str(video_path)],
        capture_output=True, text=True,
    )
    if result.returncode == 0:
        try:
            return float(result.stdout.strip())
        except ValueError:
            pass
    return 0.0


def split_video(video_path: Path, output_dir: Path, chunk_duration: float = 300.0) -> list[Path]:
    """Split a video into chunks of chunk_duration seconds. Returns sorted list of chunk paths."""
    output_dir.mkdir(parents=True, exist_ok=True)
    suffix = video_path.suffix
    output_pattern = str(output_dir / f"%d{suffix}")
    result = subprocess.run(
        [
            "ffmpeg", "-i", str(video_path),
            "-c", "copy",
            "-f", "segment",
            "-segment_time", str(int(chunk_duration)),
            "-reset_timestamps", "1",
            "-segment_start_number", "1",
            "-loglevel", "error",
            output_pattern,
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        log.error("  ffmpeg split error: %s", result.stderr)
        return []
    chunks = sorted(
        [p for p in output_dir.iterdir() if p.suffix.lower() == suffix.lower() and p.stem.isdigit()],
        key=lambda p: int(p.stem),
    )
    log.info("  Split into %d chunk(s).", len(chunks))
    return chunks


def image_hash(image_path: Path) -> str:
    """Return a perceptual-ish hash of an image using its raw bytes (fast, good enough)."""
    with open(image_path, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()


def extract_frames(video_path: Path, output_dir: Path, interval: float = 2.0) -> list[Path]:
    """
    Extract frames from a video at the given interval (seconds) using ffmpeg.
    Returns list of extracted frame paths, deduplicated by content hash.
    """
    log.info("  Extracting frames every %.1fs …", interval)
    output_pattern = str(output_dir / "frame_%06d.jpg")

    result = subprocess.run(
        [
            "ffmpeg", "-i", str(video_path),
            "-vf", f"fps=1/{interval}",
            "-q:v", "2",          # high quality JPEG
            "-loglevel", "error",
            output_pattern,
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        log.error("  ffmpeg error: %s", result.stderr)
        return []

    all_frames = sorted(output_dir.glob("frame_*.jpg"))
    log.info("  Extracted %d raw frames.", len(all_frames))

    # Deduplicate by MD5 — cookbook pages often have long static holds
    seen_hashes: set[str] = set()
    unique_frames = []
    for frame in all_frames:
        h = image_hash(frame)
        if h not in seen_hashes:
            seen_hashes.add(h)
            unique_frames.append(frame)

    removed = len(all_frames) - len(unique_frames)
    if removed:
        log.info("  Removed %d duplicate frame(s), processing %d unique frame(s).",
                 removed, len(unique_frames))

    return unique_frames


# ── Claude Vision API ──────────────────────────────────────────────────────────

EXTRACT_PROMPT = """You are a recipe extraction assistant. Look at this image carefully.
It may be a recipe photo, or a frame from a video of a cookbook page.

Extract ALL recipes visible in the image. There may be one or multiple recipes.

If the image does not show any recipe content (e.g. it is a blank page, a chapter title,
a table of contents, a photo without a recipe, or is blurry/unreadable), return an empty array.

For each recipe, return a JSON object. Return a JSON array (even if there is only one recipe).

Each recipe object must have these fields:
- "name": string — the recipe name
- "ingredients": array of strings — each ingredient as a single string e.g. "2 cups flour"
- "steps": array of strings — each instruction step as a plain string (no numbering)
- "notes": string — any notes, tips, or variations (empty string if none)
- "serves": number or null — number of servings if mentioned
- "time_hours": number or null — total time in hours if mentioned (e.g. 0.5 for 30 minutes)
- "tags": array of strings — suggested tags based on the recipe type e.g. ["Vegetarian", "Dessert"]

Rules:
- If text is partially obscured or cut off, extract what you can
- If a field is not visible in the image, use null or empty array
- Return ONLY the JSON array, no explanation, no markdown code fences
- If you cannot identify any recipe at all, return an empty array []
"""


def extract_recipes_from_image(image_path: Path) -> Optional[list[dict]]:
    """Send image to Azure OpenAI and extract structured recipe data."""
    content_type = mimetypes.guess_type(str(image_path))[0] or "image/jpeg"
    if content_type not in ("image/jpeg", "image/png", "image/gif", "image/webp"):
        content_type = "image/jpeg"

    with open(image_path, "rb") as f:
        image_data = base64.standard_b64encode(f.read()).decode("utf-8")

    payload = {
        "max_tokens": 4096,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:{content_type};base64,{image_data}",
                        },
                    },
                    {
                        "type": "text",
                        "text": EXTRACT_PROMPT,
                    },
                ],
            }
        ],
    }

    url = (
        f"{AZURE_OPENAI_ENDPOINT}/openai/deployments/{AZURE_OPENAI_DEPLOYMENT}"
        f"/chat/completions?api-version={AZURE_OPENAI_API_VERSION}"
    )
    resp = requests.post(
        url,
        headers={
            "api-key": AZURE_OPENAI_API_KEY,
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=60,
    )

    if resp.status_code == 400:
        err = resp.json().get("error", {})
        if err.get("code") == "content_filter" or "content_filter" in err.get("message", "").lower():
            log.warning("  Azure content filter blocked this image (input), skipping.")
            return None

    resp.raise_for_status()

    choice = resp.json()["choices"][0]
    if choice.get("finish_reason") == "content_filter":
        log.warning("  Azure content filter blocked this image (output), skipping.")
        return None
    text = choice["message"].get("content") or ""
    text = text.strip().lstrip("```json").lstrip("```").rstrip("```").strip()

    try:
        recipes = json.loads(text)
        if isinstance(recipes, list):
            return recipes
        if isinstance(recipes, dict):
            return [recipes]
    except json.JSONDecodeError as e:
        log.error("  Failed to parse Claude response as JSON: %s", e)
        log.debug("  Raw response: %s", text[:500])

    return []


# ── Payload builder ────────────────────────────────────────────────────────────

def build_mealie_payload(recipe: dict, tag_objects: list) -> dict:
    recipe_instructions = [
        {"id": str(uuid.uuid4()), "title": "", "text": step, "ingredientReferences": []}
        for step in recipe.get("steps", [])
    ]

    recipe_ingredients = [
        {
            "note": ing,
            "unit": None,
            "food": None,
            "disableAmount": True,
            "quantity": 0,
            "originalText": ing,
            "referenceId": "",
        }
        for ing in recipe.get("ingredients", [])
    ]

    notes = []
    if recipe.get("notes"):
        notes.append({"title": "", "text": recipe["notes"]})

    total_time = None
    try:
        hours = float(recipe.get("time_hours") or 0)
        if hours:
            total_time = int(hours * 60)
    except (ValueError, TypeError):
        pass

    serves = None
    try:
        s = recipe.get("serves")
        if s is not None:
            serves = int(s)
    except (ValueError, TypeError):
        pass

    return {
        "name": recipe["name"],
        "description": "",
        "recipeYield": str(serves) if serves else "",
        "recipeServings": serves,
        "totalTime": total_time,
        "recipeCategory": [],
        "tags": tag_objects,
        "tools": [],
        "recipeIngredient": recipe_ingredients,
        "recipeInstructions": recipe_instructions,
        "notes": notes,
        "extras": {},
        "settings": {
            "public": True,
            "showNutrition": False,
            "showAssets": False,
            "landscapeView": False,
            "disableComments": False,
            "disableAmount": True,
            "locked": False,
        },
    }


# ── Main ───────────────────────────────────────────────────────────────────────

def process_frames(frames: list[Path], source_tag: str,
                   tag_cache: dict, imported_names: set, dry_run: bool = False,
                   extra_tags: list[str] | None = None,
                   nameless_dir: Path | None = None,
                   failed_dir: Path | None = None) -> tuple[int, int, int, int]:
    """
    Process a list of image frames, extract recipes from each, and import to Mealie.
    imported_names is a shared set to deduplicate recipes across frames of the same video.
    Returns (imported, skipped, blocked, duplicate).
    """
    total_imported   = 0
    total_skipped    = 0
    total_blocked    = 0
    total_duplicate  = 0

    for frame in frames:
        recipes = extract_recipes_from_image(frame)
        if recipes is None:
            total_blocked += 1
            continue
        if not recipes:
            continue

        recipes = [r for r in recipes if isinstance(r, dict)]
        if not recipes:
            continue

        log.info("  Found %d recipe(s) in frame %s.", len(recipes), frame.name)

        for recipe in recipes:
            if "tags" not in recipe or not isinstance(recipe["tags"], list):
                recipe["tags"] = []
            for tag in [source_tag] + (extra_tags or []):
                if tag not in recipe["tags"]:
                    recipe["tags"].append(tag)

            if not recipe.get("ingredients"):
                if "no-ingredients" not in recipe["tags"]:
                    recipe["tags"].append("no-ingredients")
            if not recipe.get("steps"):
                if "no-steps" not in recipe["tags"]:
                    recipe["tags"].append("no-steps")

            name = (recipe.get("name") or "").strip()
            if not name:
                name = f"UNNAMED RECIPE {uuid.uuid4().hex[:6].upper()}"
                log.warning("  Recipe with no name, importing as '%s'.", name)
                recipe["tags"].append("needs-name")
                if nameless_dir and not dry_run:
                    nameless_dir.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(frame, nameless_dir / frame.name)

            # Deduplicate across frames (same recipe may appear on multiple frames)
            name_key = name.lower().strip()
            if name_key in imported_names:
                log.info("  Skipping duplicate: %s", name)
                continue

            log.info("  Importing: %s", name)
            imported_names.add(name_key)

            if dry_run:
                log.info("  [DRY RUN] '%s' — %d ingredients, %d steps, tags=%s",
                         name,
                         len(recipe.get("ingredients", [])),
                         len(recipe.get("steps", [])),
                         recipe.get("tags", []))
                total_imported += 1
                continue

            tag_objects = mealie_ensure_tags(recipe.get("tags", []), tag_cache)
            payload     = build_mealie_payload(recipe, tag_objects)

            slug, is_duplicate = mealie_create_recipe(name)
            if not slug:
                if is_duplicate:
                    total_duplicate += 1
                else:
                    total_skipped += 1
                    if failed_dir and not dry_run:
                        failed_dir.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(frame, failed_dir / frame.name)
                continue

            success, update_is_duplicate = mealie_update_recipe(slug, payload)
            if success:
                log.info("  ✓ Imported: %s", name)
                total_imported += 1
            elif update_is_duplicate:
                log.info("  Recipe '%s' already exists, removing empty shell.", name)
                mealie_delete_recipe(slug)
                total_duplicate += 1
            else:
                total_skipped += 1
                if failed_dir and not dry_run:
                    failed_dir.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(frame, failed_dir / frame.name)

    return total_imported, total_skipped, total_blocked, total_duplicate


def main():
    parser = argparse.ArgumentParser(description="Import recipes from photos/videos into Mealie.")
    parser.add_argument("photos_dir", help="Path to folder containing recipe photos/videos")
    parser.add_argument("--dry-run", action="store_true",
                        help="Extract recipes but do not send them to Mealie")
    args = parser.parse_args()

    dry_run = args.dry_run

    log.info("=== Recipe Photo/Video → Mealie Importer ===")

    photos_dir = Path(args.photos_dir).expanduser()
    if not photos_dir.exists():
        log.error("photos_dir '%s' does not exist.", photos_dir)
        sys.exit(1)

    processed_dir       = photos_dir / "_processed"
    no_recipe_dir       = photos_dir / "_none"
    content_filter_dir  = photos_dir / "_content_filter"
    duplicate_dir       = photos_dir / "_duplicate"
    nameless_dir        = photos_dir / "_nameless"

    _output_dirs = {"_processed", "_none", "_content_filter", "_duplicate", "_nameless"}

    all_files = sorted([
        p for p in photos_dir.rglob("*")
        if p.is_file()
        and p.suffix.lower() in SUPPORTED_EXTENSIONS
        and not any(part in _output_dirs for part in p.parts)
    ])

    def subfolder_tag(p: Path) -> str | None:
        """Return the immediate subfolder name if the file is not directly in photos_dir."""
        rel = p.relative_to(photos_dir)
        return rel.parts[0] if len(rel.parts) > 1 else None

    def move_file(p: Path, dest_root: Path) -> None:
        if dry_run:
            return
        dest_dir = dest_root / p.relative_to(photos_dir).parent
        dest_dir.mkdir(parents=True, exist_ok=True)
        p.rename(dest_dir / p.name)

    if not all_files:
        log.error("No supported files found in '%s'.", photos_dir)
        sys.exit(1)

    image_files = [f for f in all_files if f.suffix.lower() in SUPPORTED_IMAGE_EXTENSIONS]
    video_files = [f for f in all_files if f.suffix.lower() in SUPPORTED_VIDEO_EXTENSIONS]

    if PROCESS_LIMIT:
        all_files = all_files[:PROCESS_LIMIT]
        image_files = [f for f in all_files if f.suffix.lower() in SUPPORTED_IMAGE_EXTENSIONS]
        video_files = [f for f in all_files if f.suffix.lower() in SUPPORTED_VIDEO_EXTENSIONS]
        log.info("PROCESS_LIMIT=%d: processing %d image(s) and %d video(s) in %s",
                 PROCESS_LIMIT, len(image_files), len(video_files), photos_dir)
    else:
        log.info("Found %d image(s) and %d video(s) in %s",
                 len(image_files), len(video_files), photos_dir)

    if video_files and not check_ffmpeg():
        log.error("ffmpeg is required for video support but was not found. "
                  "Install it with: sudo apt install ffmpeg  OR  brew install ffmpeg")
        sys.exit(1)

    if dry_run:
        log.info("DRY RUN mode – recipes will be extracted but NOT sent to Mealie.")

    tag_cache: dict[str, dict] = {}
    if not dry_run:
        log.info("Loading existing Mealie tags …")
        tag_cache = mealie_get_tags()

    total_imported = 0
    total_skipped  = 0

    # ── Pre-split long videos ───────────────────────────────────────────────
    expanded_video_files = []
    for video_path in video_files:
        duration = get_video_duration(video_path)
        if duration > VIDEO_SPLIT_THRESHOLD:
            log.info("─── Splitting %s (%.0fs) into %.0fs chunks …",
                     video_path.name, duration, VIDEO_SPLIT_THRESHOLD)
            chunk_dir = video_path.parent / video_path.stem
            chunks = split_video(video_path, chunk_dir, VIDEO_SPLIT_THRESHOLD)
            if chunks:
                move_file(video_path, processed_dir)
                expanded_video_files.extend(chunks)
            else:
                log.warning("  Split failed, will process original.")
                expanded_video_files.append(video_path)
        else:
            expanded_video_files.append(video_path)
    video_files = expanded_video_files

    # ── Process images ──────────────────────────────────────────────────────
    for image_path in image_files:
        log.info("─── Processing image: %s", image_path.name)
        folder_tag = subfolder_tag(image_path)
        imported, skipped, blocked, duplicate = process_frames(
            frames=[image_path],
            source_tag="from_image",
            tag_cache=tag_cache,
            imported_names=set(),
            dry_run=dry_run,
            extra_tags=[folder_tag] if folder_tag else [],
            nameless_dir=nameless_dir,
            failed_dir=no_recipe_dir,
        )
        total_imported += imported
        total_skipped  += skipped
        if imported > 0:
            move_file(image_path, processed_dir)
        elif blocked > 0:
            move_file(image_path, content_filter_dir)
        elif duplicate > 0:
            move_file(image_path, duplicate_dir)
        else:
            move_file(image_path, no_recipe_dir)

    # ── Process videos ──────────────────────────────────────────────────────
    for video_path in video_files:
        log.info("─── Processing video: %s", video_path.name)
        folder_tag = subfolder_tag(video_path)
        with tempfile.TemporaryDirectory() as tmpdir:
            frames = extract_frames(video_path, Path(tmpdir), VIDEO_FRAME_INTERVAL)
            if not frames:
                log.warning("  No frames extracted from %s, skipping.", video_path.name)
                total_skipped += 1
                move_file(video_path, no_recipe_dir)
                continue
            video_tag = video_path.stem if not video_path.stem.isdigit() else None
            video_extra_tags = [t for t in [folder_tag, video_tag] if t]
            imported, skipped, blocked, duplicate = process_frames(
                frames=frames,
                source_tag="from_video",
                tag_cache=tag_cache,
                imported_names=set(),   # deduplicate within each video
                dry_run=dry_run,
                extra_tags=video_extra_tags,
                nameless_dir=nameless_dir,
                failed_dir=no_recipe_dir,
            )
            total_imported += imported
            total_skipped  += skipped

            if imported > 0:
                dest = processed_dir
            elif blocked > 0:
                dest = content_filter_dir
            elif duplicate > 0:
                dest = duplicate_dir
            else:
                dest = no_recipe_dir

            if dest != processed_dir and not dry_run:
                frames_dest = dest / video_path.relative_to(photos_dir).parent / video_path.stem
                frames_dest.mkdir(parents=True, exist_ok=True)
                for frame in frames:
                    shutil.copy2(frame, frames_dest / frame.name)
                log.info("  Saved %d frame(s) to %s", len(frames), frames_dest)

        move_file(video_path, dest)

    log.info("=== Done: %d imported, %d skipped ===", total_imported, total_skipped)



if __name__ == "__main__":
    main()