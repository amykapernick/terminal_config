#!/usr/bin/env python3
"""
Notion → Mealie Recipe Migrator
================================
Reads recipes from a Notion database and imports them into Mealie.

Requirements:
    pip install requests

Setup:
    1. NOTION_TOKEN   – Notion integration token (https://www.notion.so/my-integrations)
    2. NOTION_DB_ID   – The Notion database ID (from the database URL)
    3. MEALIE_URL     – Base URL of your Mealie instance  e.g. http://localhost:9000
    4. MEALIE_TOKEN   – Mealie API token (Profile → API Tokens)

Notion database properties (case-insensitive):
    - Title          (title)       – recipe name
    - Categories     (multi-select)→ Mealie tags
    - Time (Hours)   (number)      → Mealie totalTime (converted to minutes)
    - Serves         (number)      → Mealie recipeYield
    - Image          (url/files)   → uploaded to Mealie after recipe creation
    - Recipe Book    (select/text) → Mealie tag
    - Difficulty     – ignored
    - Page Number    – ignored
    - Notes          – ignored (page body Variations section used instead)

Ingredients, Instructions, and Variations are read from the page body,
parsed from headings matching those words.
"""

import os
import re
import sys
import uuid
import json
import logging
from typing import Optional

import requests

# ── Configuration ─────────────────────────────────────────────────────────────

NOTION_TOKEN = os.environ.get("NOTION_TOKEN", "YOUR_NOTION_TOKEN")
NOTION_DB_ID = os.environ.get("NOTION_DB_ID", "YOUR_DATABASE_ID")
MEALIE_URL   = os.environ.get("MEALIE_URL",   "http://localhost:9000").rstrip("/")
MEALIE_TOKEN = os.environ.get("MEALIE_TOKEN", "YOUR_MEALIE_TOKEN")

DRY_RUN = os.environ.get("DRY_RUN", "false").lower() == "true"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ── Notion API ─────────────────────────────────────────────────────────────────

NOTION_HEADERS = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Notion-Version": "2022-06-28",
    "Content-Type": "application/json",
}


def get_plain_text(rich_text_list: list) -> str:
    return "".join(rt.get("plain_text", "") for rt in rich_text_list)


def notion_property(props: dict, *keys: str) -> str:
    """Return plain text for the first matching property name (case-insensitive)."""
    lower_props = {k.lower(): v for k, v in props.items()}
    for key in keys:
        val = lower_props.get(key.lower())
        if not val:
            continue
        t = val.get("type")
        if t == "title":
            return get_plain_text(val.get("title", []))
        if t == "rich_text":
            return get_plain_text(val.get("rich_text", []))
        if t == "number":
            n = val.get("number")
            return str(n) if n is not None else ""
        if t == "multi_select":
            return ", ".join(o["name"] for o in val.get("multi_select", []))
        if t == "select":
            sel = val.get("select")
            return sel["name"] if sel else ""
    return ""


def notion_property_raw(props: dict, *keys: str):
    """Return the raw Notion property value for the first matching key."""
    lower_props = {k.lower(): v for k, v in props.items()}
    for key in keys:
        val = lower_props.get(key.lower())
        if val:
            return val
    return None


def notion_multi_select(props: dict, *keys: str) -> list[str]:
    """Return list of option names from a multi_select property."""
    raw = notion_property_raw(props, *keys)
    if not raw:
        return []
    t = raw.get("type")
    if t == "multi_select":
        return [o["name"] for o in raw.get("multi_select", [])]
    if t == "select":
        sel = raw.get("select")
        return [sel["name"]] if sel else []
    if t == "rich_text":
        text = get_plain_text(raw.get("rich_text", []))
        return [s.strip() for s in re.split(r"[,;]", text) if s.strip()]
    return []


def notion_image_url(props: dict) -> Optional[str]:
    """
    Extract an image URL from the 'Image' property.
    Supports: url (text), files (Notion-hosted or external).
    """
    raw = notion_property_raw(props, "image")
    if not raw:
        return None
    t = raw.get("type")
    if t == "url":
        return raw.get("url")
    if t == "rich_text":
        text = get_plain_text(raw.get("rich_text", []))
        return text.strip() or None
    if t == "files":
        files = raw.get("files", [])
        if not files:
            return None
        f = files[0]
        ft = f.get("type")
        if ft == "external":
            return f.get("external", {}).get("url")
        if ft == "file":
            return f.get("file", {}).get("url")  # temporary signed URL
    return None


def get_page_blocks(page_id: str) -> list:
    """Return all block children for a page (handles pagination)."""
    blocks = []
    cursor = None
    while True:
        params = {"page_size": 100}
        if cursor:
            params["start_cursor"] = cursor
        resp = requests.get(
            f"https://api.notion.com/v1/blocks/{page_id}/children",
            headers=NOTION_HEADERS,
            params=params,
            timeout=15,
        )
        resp.raise_for_status()
        data = resp.json()
        blocks.extend(data.get("results", []))
        if not data.get("has_more"):
            break
        cursor = data.get("next_cursor")
    return blocks


def blocks_to_markdown(blocks: list) -> str:
    """Convert Notion block list to simple markdown text."""
    lines = []
    for b in blocks:
        bt = b.get("type")
        data = b.get(bt, {})
        rich = data.get("rich_text", [])
        text = get_plain_text(rich).strip()

        if bt in ("heading_1", "heading_2", "heading_3"):
            level = int(bt[-1])
            lines.append(f"{'#' * level} {text}")
        elif bt == "bulleted_list_item":
            lines.append(f"- {text}")
        elif bt == "numbered_list_item":
            lines.append(f"1. {text}")
        elif bt == "paragraph":
            lines.append(text)
        elif bt == "divider":
            lines.append("---")
        # skip unsupported types silently
    return "\n".join(lines)


# ── Markdown / text parsers ────────────────────────────────────────────────────

def parse_ingredients(text: str) -> list[str]:
    """
    Parse ingredients from text, stripping list markers and bold formatting.
    Subsection headings (### Marinade) are ignored — all ingredients are flattened.
    """
    ingredients = []
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        # skip subheadings within the section
        if re.match(r"^#{1,4}\s+", line):
            continue
        line = re.sub(r"^[-*•]\s*", "", line)
        line = re.sub(r"^\d+\.\s*", "", line)
        line = re.sub(r"\*\*(.+?)\*\*", r"\1", line)
        if line:
            ingredients.append(line)
    return ingredients


def has_subsections(text: str) -> bool:
    """Return True if the text contains any markdown subheadings."""
    return any(re.match(r"^#{1,4}\s+", line.strip()) for line in text.splitlines())


def parse_instructions(text: str) -> list[str]:
    """Return ordered list of instruction step strings, ignoring subheadings."""
    steps = []
    current = []

    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            if current:
                steps.append(" ".join(current).strip())
                current = []
            continue
        # skip subheadings within the section
        if re.match(r"^#{1,4}\s+", stripped):
            if current:
                steps.append(" ".join(current).strip())
                current = []
            continue
        m = re.match(r"^\d+[.)]\s+(.*)", stripped)
        if m:
            if current:
                steps.append(" ".join(current).strip())
                current = []
            current.append(m.group(1))
        else:
            stripped_clean = re.sub(r"^[-*•]\s*", "", stripped)
            current.append(stripped_clean)

    if current:
        steps.append(" ".join(current).strip())

    return [s for s in steps if s]


def parse_notes(text: str) -> list[dict]:
    """
    Parse variations/notes text into a list of {title, text} dicts.
    If subheadings exist, each becomes a titled note.
    If no subheadings, returns a single note with blank title.
    """
    if not text.strip():
        return []

    if not has_subsections(text):
        return [{"title": "", "text": text.strip()}]

    notes = []
    current_title = ""
    current_lines: list[str] = []

    for line in text.splitlines():
        stripped = line.strip()
        m = re.match(r"^#{1,4}\s+(.*)", stripped)
        if m:
            if current_lines:
                body = "\n".join(current_lines).strip()
                if body:
                    notes.append({"title": current_title, "text": body})
            current_title = re.sub(r"\*\*(.+?)\*\*", r"\1", m.group(1)).strip()
            current_lines = []
        else:
            current_lines.append(line)

    if current_lines:
        body = "\n".join(current_lines).strip()
        if body:
            notes.append({"title": current_title, "text": body})

    return notes


def extract_sections(markdown: str) -> dict:
    """
    Split page markdown into named sections.
    Looks for ## or ### headings and groups content beneath them.
    Returns dict with lowercase heading names as keys.
    """
    sections: dict[str, list] = {}
    current_section = "__preamble__"
    sections[current_section] = []

    for line in markdown.splitlines():
        m = re.match(r"^#{1,4}\s+(.*)", line)
        if m:
            current_section = m.group(1).strip().lower().lstrip("*").rstrip("*").strip()
            sections.setdefault(current_section, [])
        else:
            sections[current_section].append(line)

    return {k: "\n".join(v).strip() for k, v in sections.items()}


def find_section(sections: dict, *names: str) -> str:
    """Return first section whose key contains any of the given names."""
    for name in names:
        for key, val in sections.items():
            if name.lower() in key:
                return val
    return ""


def find_sections_between(sections: dict, start_names: tuple, stop_names: tuple) -> str:
    """
    Collect all section content starting from the first section matching
    start_names, up to (but not including) the first section matching stop_names.
    This handles cases where ingredients are split across subsections like
    'ingredients', 'marinade', 'dressing' before 'method'.
    """
    keys = list(sections.keys())

    # Find the start index
    start_idx = None
    for i, key in enumerate(keys):
        if any(name.lower() in key for name in start_names):
            start_idx = i
            break
    if start_idx is None:
        return ""

    # Collect from start up to the first stop section
    collected = []
    for key in keys[start_idx:]:
        if any(name.lower() in key for name in stop_names):
            break
        if sections[key].strip():
            collected.append(sections[key])

    return "\n".join(collected)


# ── Mealie API helpers ─────────────────────────────────────────────────────────

MEALIE_HEADERS = {
    "Authorization": f"Bearer {MEALIE_TOKEN}",
    "Content-Type": "application/json",
}


def mealie_get_tags() -> dict[str, dict]:
    """Return {name_lower: {id, slug, name}} map of existing Mealie tags."""
    resp = requests.get(f"{MEALIE_URL}/api/organizers/tags?perPage=500",
                        headers=MEALIE_HEADERS, timeout=15)
    resp.raise_for_status()
    return {
        t["name"].lower(): {"id": t["id"], "slug": t["slug"], "name": t["name"]}
        for t in resp.json().get("items", [])
    }


def mealie_create_tag(name: str) -> Optional[str]:
    resp = requests.post(f"{MEALIE_URL}/api/organizers/tags",
                         headers=MEALIE_HEADERS,
                         json={"name": name}, timeout=15)
    if resp.status_code in (200, 201):
        return resp.json().get("id")
    log.warning("Could not create tag '%s': %s", name, resp.text)
    return None


def mealie_ensure_tags(names: list[str], cache: dict) -> list[dict]:
    """Return list of {id, slug, name} dicts, creating any missing tags."""
    result = []
    for name in names:
        key = name.strip().lower()
        if not key:
            continue
        tag_info = cache.get(key)
        if not tag_info:
            log.info("  Creating new tag: %s", name.strip())
            tag_id = mealie_create_tag(name.strip())
            if tag_id:
                # fetch the created tag to get its slug
                resp = requests.get(f"{MEALIE_URL}/api/organizers/tags?perPage=500",
                                    headers=MEALIE_HEADERS, timeout=15)
                all_tags = resp.json().get("items", []) if resp.status_code == 200 else []
                tag_info = next(({"id": t["id"], "slug": t["slug"], "name": t["name"]}
                                 for t in all_tags if t["id"] == tag_id), None)
                if tag_info:
                    cache[key] = tag_info
        if tag_info:
            result.append(tag_info)
    return result


def mealie_upload_image(recipe_slug: str, image_url: str) -> bool:
    """
    Download image from Notion and upload it to Mealie for the given recipe slug.
    Returns True on success.
    """
    try:
        img_resp = requests.get(image_url, timeout=30)
        img_resp.raise_for_status()
    except Exception as e:
        log.warning("  Could not download image from Notion: %s", e)
        return False

    content_type = img_resp.headers.get("Content-Type", "image/jpeg")
    ext = content_type.split("/")[-1].split(";")[0].strip() or "jpg"
    filename = f"recipe-image.{ext}"

    upload_headers = {"Authorization": f"Bearer {MEALIE_TOKEN}"}
    try:
        resp = requests.put(
            f"{MEALIE_URL}/api/recipes/{recipe_slug}/image",
            headers=upload_headers,
            files={"image": (filename, img_resp.content, content_type)},
            timeout=30,
        )
        if resp.status_code in (200, 201):
            log.info("  ✓ Image uploaded.")
            return True
        log.warning("  Image upload failed: %s %s", resp.status_code, resp.text)
    except Exception as e:
        log.warning("  Image upload error: %s", e)
    return False


def mealie_get_categories() -> dict[str, str]:
    """Return {name_lower: id} map of existing Mealie categories (unused but kept for reference)."""
    resp = requests.get(f"{MEALIE_URL}/api/organizers/categories?perPage=200",
                        headers=MEALIE_HEADERS, timeout=15)
    resp.raise_for_status()
    return {c["name"].lower(): c["id"] for c in resp.json().get("items", [])}




def build_mealie_payload(recipe: dict, tag_objects: list) -> dict:
    """Assemble the Mealie recipe creation payload."""
    # ── recipe steps (each needs a valid UUID)
    recipe_instructions = [
        {"id": str(uuid.uuid4()), "title": "", "text": step, "ingredientReferences": []}
        for step in recipe["steps"]
    ]

    # ── ingredients
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
        for ing in recipe["ingredients"]
    ]

    # ── notes parsed with titles from subheadings
    notes = parse_notes(recipe.get("variations", ""))

    # ── total time: store as hours (float)
    total_time = None
    try:
        hours = float(recipe.get("time_hours", 0) or 0)
        if hours:
            total_time = hours
    except (ValueError, TypeError):
        pass

    return {
        "name": recipe["name"],
        "description": "",
        "recipeYield": "",
        "recipeServings": int(recipe["serves"]) if recipe.get("serves") else None,
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
            "disableAmount": False,
            "locked": False,
        },
    }


def mealie_parse_ingredient(text: str) -> Optional[dict]:
    """
    Use Mealie's ingredient parser endpoint to parse a single ingredient string.
    Returns the parsed ingredient dict, or None on failure.
    """
    resp = requests.post(
        f"{MEALIE_URL}/api/parser/ingredient",
        headers=MEALIE_HEADERS,
        json={"ingredient": text},
        timeout=15,
    )
    if resp.status_code == 200:
        return resp.json()
    return None


def ingredient_is_ambiguous(parsed: Optional[dict]) -> bool:
    """
    Return True if the parsed result looks uncertain — i.e. food or unit
    couldn't be confidently matched to a known Mealie entry.
    """
    if parsed is None:
        return True
    ing = parsed.get("ingredient", {})
    # Mealie sets food/unit to None when it couldn't match them
    food_missing = ing.get("food") is None
    unit_missing = ing.get("unit") is None
    # If quantity is also 0/None the whole parse likely failed
    qty = ing.get("quantity") or 0
    return food_missing or (unit_missing and qty == 0)


def confirm_ingredient(original: str, parsed: Optional[dict]) -> str:
    """
    Interactively prompt the user to confirm or correct an ambiguous ingredient.
    Returns the final ingredient string to use (original or user-supplied).
    """
    print()
    print(f"  ⚠  Could not fully parse ingredient: \"{original}\"")
    if parsed:
        ing = parsed.get("ingredient", {})
        food = (ing.get("food") or {}).get("name", "?")
        unit = (ing.get("unit") or {}).get("name", "?")
        qty  = ing.get("quantity", "?")
        print(f"     Mealie parsed → quantity={qty}, unit={unit}, food={food}")
    else:
        print("     Mealie parser returned no result.")

    print(f"     [Enter] keep original  |  type a corrected string  |  [s] skip this ingredient")
    try:
        response = input("     > ").strip()
    except (EOFError, KeyboardInterrupt):
        print()
        return original

    if response.lower() == "s":
        return ""          # caller will filter empty strings
    if response == "":
        return original    # keep as-is
    return response        # use corrected text


def review_ingredients(ingredients: list[str]) -> list[str]:
    """
    Parse every ingredient via Mealie's parser. Prompt the user for any that
    are ambiguous. Returns the final (possibly corrected) ingredient list.
    """
    final = []
    for ing in ingredients:
        parsed = mealie_parse_ingredient(ing)
        if ingredient_is_ambiguous(parsed):
            corrected = confirm_ingredient(ing, parsed)
            if corrected:
                final.append(corrected)
            else:
                log.info("    Skipped ingredient: %s", ing)
        else:
            ing_data = parsed.get("ingredient", {})
            food = (ing_data.get("food") or {}).get("name", "")
            unit = (ing_data.get("unit") or {}).get("name", "")
            qty  = ing_data.get("quantity", "")
            log.info("    ✓ Parsed: %s  →  %s %s %s", ing, qty, unit, food)
            final.append(ing)
    return final


def mealie_create_recipe(name: str) -> Optional[str]:
    """POST to create a blank recipe by name. Returns the slug or None."""
    resp = requests.post(
        f"{MEALIE_URL}/api/recipes",
        headers=MEALIE_HEADERS,
        json={"name": name},
        timeout=30,
    )
    if resp.status_code in (200, 201):
        # Mealie returns the slug as a plain string
        slug = resp.json()
        return slug if isinstance(slug, str) else slug.get("slug")
    log.error("Failed to create recipe '%s': %s %s", name, resp.status_code, resp.text)
    return None


def mealie_update_recipe(slug: str, payload: dict) -> bool:
    """PATCH the full recipe details onto an existing slug. Returns True on success."""
    log.info("  Sending %d ingredients, %d steps to Mealie …",
             len(payload.get("recipeIngredient", [])),
             len(payload.get("recipeInstructions", [])))
    resp = requests.patch(
        f"{MEALIE_URL}/api/recipes/{slug}",
        headers=MEALIE_HEADERS,
        json=payload,
        timeout=30,
    )
    if resp.status_code in (200, 201):
        data = resp.json()
        log.info("  Mealie confirmed %d ingredients, %d steps stored.",
                 len(data.get("recipeIngredient", [])),
                 len(data.get("recipeInstructions", [])))
        return True
    log.error("Failed to update recipe '%s': %s %s", slug, resp.status_code, resp.text)
    return False


# ── Main pipeline ──────────────────────────────────────────────────────────────

def fetch_notion_recipes() -> list[dict]:
    """Fetch all pages from the Notion database and parse them into dicts."""
    recipes = []
    cursor = None

    while True:
        body: dict = {"page_size": 100}
        if cursor:
            body["start_cursor"] = cursor
        resp = requests.post(
            f"https://api.notion.com/v1/databases/{NOTION_DB_ID}/query",
            headers=NOTION_HEADERS,
            json=body,
            timeout=15,
        )
        resp.raise_for_status()
        data = resp.json()
        pages = data.get("results", [])

        for page in pages:
            props = page.get("properties", {})

            name = notion_property(props, "Name", "Title", "Recipe")
            if not name:
                log.warning("Skipping page with no title: %s", page["id"])
                continue

            log.info("Reading: %s", name)

            # Categories (multi-select) → tags
            categories = notion_multi_select(props, "categories", "category")

            # Recipe Book (select or text) → additional tag
            recipe_book = notion_property(props, "recipe book", "book", "collection")

            # Combine into a single tag list (deduplicated)
            all_tags = categories[:]
            if recipe_book and recipe_book not in all_tags:
                all_tags.append(recipe_book)

            # Time (Hours) → keep as float for conversion later
            time_hours_raw = notion_property(props, "time (hours)", "time", "duration")
            try:
                time_hours = float(time_hours_raw) if time_hours_raw else None
            except ValueError:
                time_hours = None

            # Serves → string for recipeYield
            serves = notion_property(props, "serves", "servings", "yield")

            # Image URL (may be None if empty)
            image_url = notion_image_url(props)

            # Page body → sections
            blocks   = get_page_blocks(page["id"])
            markdown = blocks_to_markdown(blocks)
            sections = extract_sections(markdown)

            INSTRUCTION_NAMES = ("instruction", "step", "method", "direction")
            VARIATION_NAMES   = ("variation", "note", "tip", "alteration")

            ingredients_text  = find_sections_between(sections,
                                    start_names=("ingredient",),
                                    stop_names=INSTRUCTION_NAMES + VARIATION_NAMES)
            instructions_text = find_section(sections, *INSTRUCTION_NAMES)
            variations_text   = find_section(sections, *VARIATION_NAMES)

            log.info("  Sections found: %s", [k for k in sections if k != "__preamble__"])

            ingredients = parse_ingredients(ingredients_text)
            steps       = parse_instructions(instructions_text)

            # Detect subsections by checking if there are extra section keys between
            # the ingredients heading and the instructions heading
            all_keys = [k for k in sections.keys() if k != "__preamble__"]
            ing_names = ("ingredient",)
            ing_idx  = next((i for i, k in enumerate(all_keys) if any(n in k for n in ing_names)), None)
            inst_idx = next((i for i, k in enumerate(all_keys) if any(n in k for n in INSTRUCTION_NAMES)), None)
            if ing_idx is not None and inst_idx is not None and inst_idx - ing_idx > 1:
                if "subsections" not in all_tags:
                    all_tags.append("subsections")

            if not ingredients:
                if "no-ingredients" not in all_tags:
                    all_tags.append("no-ingredients")

            if not steps:
                if "no-steps" not in all_tags:
                    all_tags.append("no-steps")

            recipes.append({
                "name":       name,
                "tags":       all_tags,
                "time_hours": time_hours,
                "serves":     serves,
                "image_url":  image_url,
                "ingredients": ingredients,
                "steps":      steps,
                "variations": variations_text,
            })

        if not data.get("has_more"):
            break
        cursor = data.get("next_cursor")

    return recipes


def main():
    log.info("=== Notion → Mealie Recipe Migrator ===")

    if DRY_RUN:
        log.info("DRY RUN mode – recipes will be parsed but NOT sent to Mealie.")

    # 1. Fetch recipes from Notion
    log.info("Fetching recipes from Notion database %s …", NOTION_DB_ID)
    recipes = fetch_notion_recipes()
    log.info("Found %d recipe(s).", len(recipes))

    if not recipes:
        log.warning("No recipes found. Check your NOTION_DB_ID and integration permissions.")
        sys.exit(0)

    # 2. Pre-load Mealie tags
    tag_cache: dict[str, dict] = {}
    if not DRY_RUN:
        log.info("Loading existing Mealie tags …")
        tag_cache = mealie_get_tags()

    # 3. Import each recipe
    success, skipped = 0, 0
    for recipe in recipes:
        log.info("─── Importing: %s", recipe["name"])

        if DRY_RUN:
            log.info("  [DRY RUN] %d ingredients, %d steps, tags=%s, serves=%s, time=%sh, image=%s",
                     len(recipe["ingredients"]), len(recipe["steps"]),
                     recipe["tags"], recipe["serves"], recipe["time_hours"],
                     "yes" if recipe["image_url"] else "no")
            log.info("  Ingredients: %s", recipe["ingredients"])
            log.info("  Variations:  %s", (recipe["variations"] or "")[:120])
            success += 1
            continue

        tag_objects = mealie_ensure_tags(recipe["tags"], tag_cache)
        payload     = build_mealie_payload(recipe, tag_objects)

        slug = mealie_create_recipe(recipe["name"])
        if not slug:
            skipped += 1
            continue

        if mealie_update_recipe(slug, payload):
            log.info("  ✓ Created and updated: %s (slug: %s)", recipe["name"], slug)

            # Upload image if present
            if recipe.get("image_url"):
                log.info("  Uploading image …")
                mealie_upload_image(slug, recipe["image_url"])

            success += 1
        else:
            skipped += 1

    log.info("=== Done: %d imported, %d skipped ===", success, skipped)


if __name__ == "__main__":
    main()
