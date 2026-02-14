#!/bin/bash
# -------------------------------------------------------------------
# Clipboard Rewriter — shell wrapper
# -------------------------------------------------------------------
# This script is meant to be called from an Automator Quick Action
# so it can be bound to a global keyboard shortcut.
#
# It sources your shell profile to pick up OPENAI_API_KEY,
# then runs the Python rewriter.
# -------------------------------------------------------------------

# Source shell profile for environment variables
if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc" 2>/dev/null
elif [ -f "$HOME/.bash_profile" ]; then
    source "$HOME/.bash_profile" 2>/dev/null
elif [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null
fi

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Default mode — override by passing an argument (e.g. "pro", "cas", "fix")
MODE="${1:-default}"

# Run the rewriter
/opt/homebrew/bin/python3 "$SCRIPT_DIR/rewrite.py" --mode "$MODE"
