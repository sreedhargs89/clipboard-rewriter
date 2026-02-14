# ✏️ Clipboard Rewriter

A macOS productivity tool that rewrites your clipboard contents using OpenAI — triggered by a keyboard shortcut.

## How It Works

```
Copy text → Press hotkey → Paste rewritten text
```

1. **Copy** any text to your clipboard (`⌘C`)
2. **Press your hotkey** (e.g. `⌥R`) — the tool reads your clipboard, sends it to OpenAI, and replaces the clipboard with the rewritten version
3. **Paste** (`⌘V`) — you get the polished, rewritten text

## Rewriting Modes

| Mode | Alias | Description |
|------|-------|-------------|
| **Default** | `default`, `def`, `d` | General rewrite — clearer, more polished |
| **Professional** | `professional`, `pro`, `p` | Formal business tone |
| **Casual** | `casual`, `cas`, `c` | Friendly, conversational tone |
| **Fix Grammar** | `fix`, `grammar`, `f`, `g` | Only fix grammar/spelling errors |
| **Prompt** | `prompt`, `pr` | Turns rough ideas into well-crafted AI prompts |

## Quick Start

### 1. Set your OpenAI API key

Add this to your `~/.zshrc`:

```bash
export OPENAI_API_KEY='sk-...your-key-here...'
```


Then reload: `source ~/.zshrc`

### 2. Run the setup script

```bash
cd /Users/sree/prod-tools/clipboard-rewriter
bash setup.sh
```

This will:
- Verify the `openai` Python package is installed
- Create 4 Automator Quick Actions (one per mode)
- Print instructions for assigning keyboard shortcuts

### 3. Assign keyboard shortcuts

1. **System Settings** → **Keyboard** → **Keyboard Shortcuts** → **Services**
2. Scroll to the **General** section
3. Assign hotkeys to:
   - `Clipboard Rewriter` → `⌥R`
   - `Clipboard Rewriter (Professional)` → `⌥P`
   - `Clipboard Rewriter (Casual)` → `⌥C`
   - `Clipboard Rewriter (Fix Grammar)` → `⌥G`
   - `Clipboard Rewriter (Prompt)` → `⌥W`

### 4. Use it!

Copy text → press your hotkey → paste the rewritten version.

## Terminal Usage

You can also run the tool directly from the terminal:

```bash
# Default rewrite
./rewrite.sh

# Professional tone
./rewrite.sh pro

# Casual tone
./rewrite.sh cas

# Fix grammar only
./rewrite.sh fix

# Turn rough text into a professional prompt
./rewrite.sh prompt

# Or use the Python script directly
python3 rewrite.py --mode professional
```

## Configuration

The tool auto-generates a `config.json` on first run. Edit it to customise:

```json
{
  "model": "gpt-4o-mini",
  "temperature": 0.7,
  "prompts": {
    "default": "Your custom default prompt...",
    "professional": "Your custom professional prompt...",
    "casual": "Your custom casual prompt...",
    "fix": "Your custom grammar-fix prompt..."
  }
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `model` | `gpt-4o-mini` | OpenAI model to use (try `gpt-4o` for higher quality) |
| `temperature` | `0.7` | Creativity level (0 = deterministic, 1 = creative) |
| `prompts` | See `config.json` | System prompts for each rewriting mode |

## File Structure

```
clipboard-rewriter/
├── README.md          ← you are here
├── rewrite.py         ← main Python script
├── rewrite.sh         ← shell wrapper (for Automator)
├── setup.sh           ← one-time setup script
└── config.json        ← auto-generated on first run
```

## Troubleshooting

### "OPENAI_API_KEY is not set"
Make sure the key is exported in `~/.zshrc` and you've run `source ~/.zshrc`.

### Hotkey doesn't work
- Check that the Quick Actions appear in **System Settings → Keyboard → Keyboard Shortcuts → Services → General**
- macOS may require you to grant **Accessibility** permissions to Automator
- Try running `./rewrite.sh` from the terminal first to verify the script works

### "Clipboard is empty"
Copy some text first with `⌘C`, then press the hotkey.