#!/opt/homebrew/bin/python3
"""
Clipboard Rewriter — powered by OpenAI
=======================================
Reads the current clipboard contents, sends them to OpenAI for rewriting,
and places the rewritten text back on the clipboard.

Usage:
    python3 rewrite.py              # rewrite clipboard contents
    python3 rewrite.py --mode pro   # use "professional" preset
    python3 rewrite.py --mode cas   # use "casual" preset
    python3 rewrite.py --mode fix   # just fix grammar / spelling

Environment:
    OPENAI_API_KEY  — your OpenAI API key (required)
"""

import subprocess
import sys
import os
import json
import argparse
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

CONFIG_PATH = Path(__file__).parent / "config.json"

DEFAULT_CONFIG = {
    "model": "gpt-4o-mini",
    "temperature": 0.7,
    "prompts": {
        "default": (
            "You are a writing assistant. "
            "Rewrite the following text to be clearer and more polished "
            "while preserving the original meaning, tone, and FORMAT. "
            "Keep it as regular text — do NOT convert it into an email, letter, or any other format. "
            "Do NOT add greetings, sign-offs, subject lines, or signatures. "
            "Do NOT add any preamble, explanation, or commentary — return ONLY the rewritten text."
        ),
        "professional": (
            "You are a writing assistant. "
            "Rewrite the following text in a professional, polished tone while keeping the SAME format. "
            "If the input is a short message or note, keep it as a short message or note. "
            "Do NOT convert it into an email, letter, or formal document. "
            "Do NOT add greetings, sign-offs, subject lines, or signatures. "
            "Just improve the wording to sound more professional. "
            "Do NOT add any preamble, explanation, or commentary — return ONLY the rewritten text."
        ),
        "casual": (
            "You are a writing assistant. "
            "Rewrite the following text in a casual, friendly tone while keeping the SAME format. "
            "If the input is a short message, keep it short. "
            "Do NOT convert it into an email or letter. "
            "Do NOT add greetings, sign-offs, or signatures. "
            "Just make it sound more natural and conversational. "
            "Do NOT add any preamble, explanation, or commentary — return ONLY the rewritten text."
        ),
        "fix": (
            "You are a grammar and spelling expert. "
            "Fix any grammar, spelling, or punctuation errors in the following text. "
            "Do NOT change the meaning, tone, style, or format — only correct errors. "
            "Do NOT add any preamble, explanation, or commentary — return ONLY the corrected text."
        ),
        "prompt": (
            "You are an elite AI prompt engineer. "
            "Take the following rough idea or text and rewrite it as a clear, well-structured, and highly effective prompt. "
            "Apply prompt engineering best practices: be specific, provide context, define the desired output format, set constraints, "
            "and use role-based framing where appropriate. "
            "Make the prompt detailed enough to get excellent results from an AI model. "
            "Do NOT add any preamble, explanation, or commentary — return ONLY the rewritten prompt."
        ),
    },
}

MODE_ALIASES = {
    "default": "default",
    "def": "default",
    "d": "default",
    "professional": "professional",
    "pro": "professional",
    "p": "professional",
    "casual": "casual",
    "cas": "casual",
    "c": "casual",
    "fix": "fix",
    "grammar": "fix",
    "f": "fix",
    "g": "fix",
    "prompt": "prompt",
    "pr": "prompt",
}


def load_config() -> dict:
    """Load config from file, falling back to defaults."""
    if CONFIG_PATH.exists():
        try:
            with open(CONFIG_PATH) as f:
                user_cfg = json.load(f)
            # Merge: user overrides win
            cfg = {**DEFAULT_CONFIG, **user_cfg}
            cfg["prompts"] = {**DEFAULT_CONFIG["prompts"], **user_cfg.get("prompts", {})}
            return cfg
        except Exception:
            pass
    return DEFAULT_CONFIG


def save_default_config():
    """Write the default config to disk so the user can customise it."""
    if not CONFIG_PATH.exists():
        with open(CONFIG_PATH, "w") as f:
            json.dump(DEFAULT_CONFIG, f, indent=2)


# ---------------------------------------------------------------------------
# Clipboard helpers (macOS native — no dependencies)
# ---------------------------------------------------------------------------

def get_clipboard() -> str:
    """Read clipboard contents using macOS pbpaste."""
    result = subprocess.run(["pbpaste"], capture_output=True, text=True)
    return result.stdout


def set_clipboard(text: str):
    """Write text to clipboard using macOS pbcopy."""
    subprocess.run(["pbcopy"], input=text, text=True)


# ---------------------------------------------------------------------------
# macOS notification helper
# ---------------------------------------------------------------------------

def notify(title: str, message: str):
    """Send a macOS notification."""
    # Escape double quotes for AppleScript
    safe_title = title.replace('"', '\\"')
    safe_msg = message.replace('"', '\\"')
    script = f'display notification "{safe_msg}" with title "{safe_title}"'
    subprocess.run(["osascript", "-e", script], capture_output=True)


# ---------------------------------------------------------------------------
# OpenAI rewriting
# ---------------------------------------------------------------------------

def rewrite_text(text: str, config: dict, mode: str = "default") -> str:
    """Send text to OpenAI and return the rewritten version."""
    from openai import OpenAI

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise EnvironmentError(
            "OPENAI_API_KEY is not set. "
            "Export it in your shell profile:\n"
            "  export OPENAI_API_KEY='sk-...'"
        )

    client = OpenAI(api_key=api_key)

    system_prompt = config["prompts"].get(mode, config["prompts"]["default"])

    response = client.chat.completions.create(
        model=config.get("model", "gpt-4o-mini"),
        temperature=config.get("temperature", 0.7),
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": text},
        ],
    )

    return response.choices[0].message.content.strip()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Rewrite clipboard contents with OpenAI")
    parser.add_argument(
        "--mode", "-m",
        default="default",
        help="Rewriting mode: default | professional/pro | casual/cas | fix/grammar",
    )
    parser.add_argument(
        "--init-config",
        action="store_true",
        help="Write default config.json and exit",
    )
    args = parser.parse_args()

    if args.init_config:
        save_default_config()
        print(f"✅ Default config written to {CONFIG_PATH}")
        return

    config = load_config()
    save_default_config()  # Ensure config exists for future edits

    # Resolve mode alias
    mode = MODE_ALIASES.get(args.mode.lower(), "default")

    # 1. Read clipboard
    original = get_clipboard()
    if not original.strip():
        notify("Clipboard Rewriter", "⚠️ Clipboard is empty — nothing to rewrite.")
        print("⚠️  Clipboard is empty.")
        sys.exit(1)

    notify("Clipboard Rewriter", f"✏️ Rewriting ({mode} mode)…")
    print(f"📋 Original ({len(original)} chars):\n{original[:200]}{'…' if len(original) > 200 else ''}\n")

    # 2. Rewrite via OpenAI
    try:
        rewritten = rewrite_text(original, config, mode)
    except Exception as e:
        notify("Clipboard Rewriter", f"❌ Error: {e}")
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)

    # 3. Put rewritten text on clipboard
    set_clipboard(rewritten)

    preview = rewritten[:200] + ("…" if len(rewritten) > 200 else "")
    notify("Clipboard Rewriter", f"✅ Done! Rewritten text is on your clipboard.")
    print(f"✅ Rewritten ({len(rewritten)} chars):\n{rewritten}\n")
    print("📋 The rewritten text is now on your clipboard — just paste it!")


if __name__ == "__main__":
    main()
