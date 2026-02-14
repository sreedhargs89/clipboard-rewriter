# Clipboard Rewriter

A macOS productivity tool that rewrites your clipboard contents using OpenAI — accessible from the menu bar, keyboard shortcuts, or terminal.

## How It Works

```
Copy text → Click menu bar / press hotkey → Paste rewritten text
```

1. **Copy** any text to your clipboard (`Cmd+C`)
2. **Trigger a rewrite** — via the menu bar icon, a global hotkey, or the terminal
3. **Paste** (`Cmd+V`) — you get the polished, rewritten text

## Trigger Methods

### Menu Bar App (Recommended)

A persistent menu bar icon gives you one-click access to all rewriting modes — no manual hotkey configuration needed.

```
[Menu Bar ✏️] (click to open)
├── Rewrite (Default)       ⌥R
├── Professional Tone       ⌥P
├── Casual Tone             ⌥C
├── Fix Grammar             ⌥G
├── AI Prompt Mode          ⌥W
├── ─────────────
├── Settings
│   ├── Open config.json
│   └── Reload Config
├── Global Hotkeys: ON/OFF
├── ─────────────
├── About
└── Quit
```

**Advantages over keyboard shortcuts alone:**
- No manual System Settings configuration
- All modes visible and discoverable at a glance
- Built-in global hotkeys registered automatically
- Visual status feedback (icon changes while processing)
- Settings and config access from the menu

### Keyboard Shortcuts

Global hotkeys work automatically when the menu bar app is running:

| Shortcut | Mode |
|----------|------|
| `⌥R` (Option+R) | Default rewrite |
| `⌥P` (Option+P) | Professional tone |
| `⌥C` (Option+C) | Casual tone |
| `⌥G` (Option+G) | Fix grammar |
| `⌥W` (Option+W) | AI prompt mode |

You can toggle hotkeys on/off from the menu bar dropdown.

### Terminal

```bash
./rewrite.sh              # default rewrite
./rewrite.sh pro          # professional tone
./rewrite.sh cas          # casual tone
./rewrite.sh fix          # fix grammar only
./rewrite.sh prompt       # AI prompt engineering
python3 rewrite.py --mode professional
```

## Rewriting Modes

| Mode | Aliases | Description |
|------|---------|-------------|
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
bash setup.sh
```

This will:
- Install Python dependencies (`openai`, `rumps`, `pynput`)
- Make scripts executable
- Create Automator Quick Actions (optional fallback)
- Print instructions for launching the menu bar app

### 3. Launch the menu bar app

```bash
python3 menubar_app.py &
```

You'll see a ✏️ icon in your menu bar. Click it to access all rewriting modes.

### 4. (Optional) Auto-launch on login

To start the menu bar app automatically when you log in:

1. Open **System Settings** → **General** → **Login Items**
2. Click **+** and add `menubar_app.py`

Or create a Launch Agent:

```bash
cat > ~/Library/LaunchAgents/com.clipboard-rewriter.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.clipboard-rewriter</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/python3</string>
        <string>$(pwd)/menubar_app.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF
launchctl load ~/Library/LaunchAgents/com.clipboard-rewriter.plist
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
    "fix": "Your custom grammar-fix prompt...",
    "prompt": "Your custom prompt-engineer prompt..."
  }
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `model` | `gpt-4o-mini` | OpenAI model to use (try `gpt-4o` for higher quality) |
| `temperature` | `0.7` | Creativity level (0 = deterministic, 1 = creative) |
| `prompts` | See `config.json` | System prompts for each rewriting mode |

You can reload the config from the menu bar without restarting the app.

## File Structure

```
clipboard-rewriter/
├── README.md              ← you are here
├── menubar_app.py         ← menu bar application (recommended)
├── rewrite.py             ← core rewriting logic
├── rewrite.sh             ← shell wrapper (for Automator / terminal)
├── setup.sh               ← one-time setup script
├── install_hotkeys.sh     ← Automator Quick Actions installer (alternative)
├── config.json            ← auto-generated on first run
└── requirements.txt       ← Python dependencies
```

## Requirements

- macOS 10.15+ (Catalina or later)
- Python 3.8+
- OpenAI API key

Python packages (installed by `setup.sh` or `pip3 install -r requirements.txt`):
- `openai` — OpenAI API client
- `rumps` — macOS menu bar framework
- `pynput` — global hotkey support (optional, hotkeys disabled without it)

## Troubleshooting

### "OPENAI_API_KEY is not set"
Make sure the key is exported in `~/.zshrc` and you've run `source ~/.zshrc`. The menu bar app also reads from your shell profile on startup.

### Menu bar icon doesn't appear
- Make sure `rumps` is installed: `pip3 install rumps`
- Run from terminal to see error output: `python3 menubar_app.py`

### Hotkeys don't work
- Check that `pynput` is installed: `pip3 install pynput`
- macOS may require **Accessibility** permissions: System Settings → Privacy & Security → Accessibility → enable your terminal app
- You can still use the menu bar click interface without hotkeys

### Automator Quick Actions don't appear (legacy method)
- Check **System Settings → Keyboard → Keyboard Shortcuts → Services → General**
- macOS may require you to grant **Accessibility** permissions to Automator
- Try logging out and back in
- Try running `./rewrite.sh` from the terminal first to verify the script works

### "Clipboard is empty"
Copy some text first with `Cmd+C`, then trigger the rewrite.

### Menu bar app crashes on launch
- Run `python3 menubar_app.py` in the terminal to see the error
- Ensure all dependencies are installed: `pip3 install -r requirements.txt`
