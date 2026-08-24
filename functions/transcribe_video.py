#!/usr/bin/env python3
"""
Video → Timestamped Transcription
====================================
Extracts audio from a video file and produces a full timestamped transcription
using Azure OpenAI Whisper.

Requirements:
    pip install requests python-dotenv

Setup:
    AZURE_OPENAI_API_KEY              – Azure OpenAI API key
    AZURE_OPENAI_ENDPOINT             – e.g. https://my-resource.openai.azure.com
    AZURE_OPENAI_WHISPER_DEPLOYMENT   – Your Whisper deployment name e.g. whisper

Usage:
    python3 transcribe_video.py video.mp4
    python3 transcribe_video.py video.mp4 -o transcript.txt
    python3 transcribe_video.py video.mp4 --format srt
    python3 transcribe_video.py video.mp4 --format json
    python3 transcribe_video.py video.mp4 --language en
"""

import argparse
import json
import logging
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import requests
from dotenv import load_dotenv

load_dotenv(Path.home() / ".env")

# ── Configuration ──────────────────────────────────────────────────────────────

AZURE_OPENAI_API_KEY            = os.environ.get("AZURE_OPENAI_API_KEY", "")
AZURE_OPENAI_ENDPOINT           = os.environ.get("AZURE_OPENAI_ENDPOINT", "").rstrip("/")
AZURE_OPENAI_WHISPER_DEPLOYMENT = os.environ.get("AZURE_OPENAI_WHISPER_DEPLOYMENT", "whisper")
AZURE_OPENAI_API_VERSION        = "2024-02-01"

# Azure Whisper limit is 25 MB; use 24 MB to leave headroom
MAX_CHUNK_BYTES = 24 * 1024 * 1024

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ── ffmpeg helpers ─────────────────────────────────────────────────────────────

def check_ffmpeg() -> bool:
    try:
        subprocess.run(["ffmpeg", "-version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def get_duration(path: Path) -> float:
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
         "-of", "csv=p=0", str(path)],
        capture_output=True, text=True,
    )
    if result.returncode == 0:
        try:
            return float(result.stdout.strip())
        except ValueError:
            pass
    return 0.0


def extract_audio(video_path: Path, output_path: Path) -> None:
    result = subprocess.run(
        [
            "ffmpeg", "-i", str(video_path),
            "-vn",                   # strip video
            "-acodec", "libmp3lame",
            "-q:a", "4",             # ~128 kbps VBR
            "-loglevel", "error",
            "-y", str(output_path),
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"ffmpeg audio extraction failed: {result.stderr}")


def split_audio(audio_path: Path, output_dir: Path, chunk_duration: float) -> list[Path]:
    output_pattern = str(output_dir / "chunk_%04d.mp3")
    result = subprocess.run(
        [
            "ffmpeg", "-i", str(audio_path),
            "-f", "segment",
            "-segment_time", str(int(chunk_duration)),
            "-acodec", "copy",
            "-reset_timestamps", "1",
            "-loglevel", "error",
            "-y", output_pattern,
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"ffmpeg split failed: {result.stderr}")
    return sorted(output_dir.glob("chunk_*.mp3"), key=lambda p: int(p.stem.split("_")[1]))


# ── Azure Whisper API ──────────────────────────────────────────────────────────

def transcribe_chunk(audio_path: Path, language: str | None = None) -> list[dict]:
    """Transcribe one audio chunk. Returns list of segment dicts with start/end/text."""
    url = (
        f"{AZURE_OPENAI_ENDPOINT}/openai/deployments/{AZURE_OPENAI_WHISPER_DEPLOYMENT}"
        f"/audio/transcriptions?api-version={AZURE_OPENAI_API_VERSION}"
    )
    form: dict[str, str] = {"response_format": "verbose_json"}
    if language:
        form["language"] = language

    with open(audio_path, "rb") as f:
        resp = requests.post(
            url,
            headers={"api-key": AZURE_OPENAI_API_KEY},
            files={"file": (audio_path.name, f, "audio/mpeg")},
            data=form,
            timeout=300,
        )
    resp.raise_for_status()
    return resp.json().get("segments", [])


# ── Output formatters ──────────────────────────────────────────────────────────

def _hms(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = seconds % 60
    return f"{h:02d}:{m:02d}:{s:06.3f}"


def _srt_hms(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int((seconds % 1) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def format_text(segments: list[dict]) -> str:
    return "\n".join(f"[{_hms(seg['start'])}] {seg['text'].strip()}" for seg in segments)


def format_srt(segments: list[dict]) -> str:
    blocks = [
        f"{i}\n{_srt_hms(seg['start'])} --> {_srt_hms(seg['end'])}\n{seg['text'].strip()}"
        for i, seg in enumerate(segments, 1)
    ]
    return "\n\n".join(blocks)


def format_json(segments: list[dict]) -> str:
    return json.dumps(segments, indent=2, ensure_ascii=False)


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Transcribe a video file with timestamps using Azure OpenAI Whisper."
    )
    parser.add_argument("video", help="Path to the video file")
    parser.add_argument("-o", "--output", help="Output file (default: <video>.srt)")
    parser.add_argument(
        "--format", choices=["text", "srt", "json"], default="srt",
        help="Output format (default: srt)"
    )
    parser.add_argument(
        "--language",
        help="ISO-639-1 language code to hint Whisper e.g. en, es, fr (default: auto-detect)"
    )
    args = parser.parse_args()

    if not check_ffmpeg():
        log.error("ffmpeg/ffprobe is required but was not found.")
        sys.exit(1)

    if not AZURE_OPENAI_API_KEY or not AZURE_OPENAI_ENDPOINT:
        log.error("AZURE_OPENAI_API_KEY and AZURE_OPENAI_ENDPOINT must be set (check ~/.env).")
        sys.exit(1)

    video_path = Path(args.video).expanduser().resolve()
    if not video_path.exists():
        log.error("File not found: %s", video_path)
        sys.exit(1)

    log.info("=== Video → Transcription ===")
    log.info("Input:      %s", video_path.name)
    log.info("Deployment: %s", AZURE_OPENAI_WHISPER_DEPLOYMENT)

    all_segments: list[dict] = []

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        audio_path = tmp / "audio.mp3"

        log.info("Extracting audio …")
        extract_audio(video_path, audio_path)

        audio_size = audio_path.stat().st_size
        duration   = get_duration(audio_path)
        log.info("Audio: %.1f MB, %.1f s", audio_size / 1024 / 1024, duration)

        if audio_size <= MAX_CHUNK_BYTES:
            log.info("Transcribing …")
            all_segments = transcribe_chunk(audio_path, args.language)
        else:
            bytes_per_sec  = audio_size / duration if duration else audio_size
            chunk_duration = MAX_CHUNK_BYTES / bytes_per_sec * 0.95  # 5% headroom
            log.info("File exceeds 24 MB — splitting into ~%.0f-second chunks …", chunk_duration)

            chunks_dir = tmp / "chunks"
            chunks_dir.mkdir()
            chunks = split_audio(audio_path, chunks_dir, chunk_duration)
            log.info("Split into %d chunk(s).", len(chunks))

            offset = 0.0
            for i, chunk in enumerate(chunks, 1):
                log.info("Transcribing chunk %d/%d …", i, len(chunks))
                segments = transcribe_chunk(chunk, args.language)
                for seg in segments:
                    seg["start"] += offset
                    seg["end"]   += offset
                all_segments.extend(segments)
                offset += get_duration(chunk)

    log.info("Transcribed %d segment(s).", len(all_segments))

    if args.format == "srt":
        output = format_srt(all_segments)
    elif args.format == "json":
        output = format_json(all_segments)
    else:
        output = format_text(all_segments)

    ext = {"text": ".txt", "srt": ".srt", "json": ".json"}[args.format]
    out_path = Path(args.output).expanduser() if args.output else video_path.with_suffix(ext)
    out_path.write_text(output, encoding="utf-8")
    log.info("Transcript written to %s", out_path)

    log.info("=== Done ===")


if __name__ == "__main__":
    main()
