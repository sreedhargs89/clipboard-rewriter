#!/opt/homebrew/bin/python3
"""
Clipboard Rewriter — macOS Menu Bar App
========================================
A persistent menu bar application that provides one-click access to all
clipboard rewriting modes. No manual hotkey configuration needed.

Usage:
    python3 menubar_app.py          # Launch the menu bar app
    python3 menubar_app.py &        # Launch in background

Requirements:
    pip3 install rumps pynput openai
"""

import os
import sys
import threading
import subprocess
import json
from pathlib import Path

try:
    import rumps
except ImportError:
    print(
        "ERROR: 'rumps' is not installed.\n"
        "Install it with:  pip3 install rumps\n"
        "Or run:  pip3 install -r requirements.txt"
    )
    sys.exit(1)

# Import rewriting logic from the existing module
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR))
from rewrite import load_config, get_clipboard, set_clipboard, rewrite_text, notify

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

APP_NAME = "Clipboard Rewriter"
ICON_IDLE = None  # Uses title text when no icon file is present
TITLE_IDLE = "✏️"
TITLE_BUSY = "⏳"

MODES = [
    ("Rewrite (Default)", "default", "⌥R"),
    ("Professional Tone", "professional", "⌥P"),
    ("Casual Tone", "casual", "⌥C"),
    ("Fix Grammar", "fix", "⌥G"),
    ("AI Prompt Mode", "prompt", "⌥W"),
]

# Global hotkey mappings: key_char -> mode
HOTKEY_MAP = {
    "r": "default",
    "p": "professional",
    "c": "casual",
    "g": "fix",
    "w": "prompt",
}


# ---------------------------------------------------------------------------
# Menu Bar Application
# ---------------------------------------------------------------------------

class ClipboardRewriterApp(rumps.App):
    """macOS menu bar app for clipboard rewriting."""

    def __init__(self):
        super().__init__(APP_NAME, title=TITLE_IDLE, quit_button=None)
        self.config = load_config()
        self._busy = False
        self._hotkeys_active = False
        self._hotkey_listener = None

        # Build menu
        self._build_menu()

        # Start global hotkeys in background
        self._start_hotkeys()

    def _build_menu(self):
        """Construct the menu bar dropdown."""
        menu_items = []

        # Rewriting mode buttons
        for label, mode, shortcut in MODES:
            item = rumps.MenuItem(
                f"{label}    {shortcut}",
                callback=self._make_rewrite_callback(mode),
            )
            menu_items.append(item)

        menu_items.append(rumps.separator)

        # Settings submenu
        settings_menu = rumps.MenuItem("Settings")
        settings_menu.add(rumps.MenuItem("Open config.json", callback=self._open_config))
        settings_menu.add(rumps.MenuItem("Reload Config", callback=self._reload_config))
        menu_items.append(settings_menu)

        # Hotkeys toggle
        self._hotkeys_item = rumps.MenuItem(
            "Global Hotkeys: ON",
            callback=self._toggle_hotkeys,
        )
        menu_items.append(self._hotkeys_item)

        menu_items.append(rumps.separator)

        # About & Quit
        menu_items.append(rumps.MenuItem("About", callback=self._show_about))
        menu_items.append(rumps.MenuItem("Quit", callback=self._quit))

        self.menu = menu_items

    # ----- Rewriting logic -----

    def _make_rewrite_callback(self, mode):
        """Return a callback function for the given rewrite mode."""

        def callback(sender):
            self._do_rewrite(mode)

        return callback

    def _do_rewrite(self, mode):
        """Run the clipboard rewrite in a background thread."""
        if self._busy:
            rumps.notification(
                APP_NAME,
                "Please wait",
                "A rewrite is already in progress.",
            )
            return

        thread = threading.Thread(target=self._rewrite_worker, args=(mode,), daemon=True)
        thread.start()

    def _rewrite_worker(self, mode):
        """Background worker that performs the actual rewrite."""
        self._busy = True
        self.title = TITLE_BUSY

        try:
            # Read clipboard
            original = get_clipboard()
            if not original.strip():
                rumps.notification(APP_NAME, "Nothing to rewrite", "Clipboard is empty.")
                return

            rumps.notification(APP_NAME, f"Rewriting ({mode})...", "Please wait a moment.")

            # Call OpenAI
            rewritten = rewrite_text(original, self.config, mode)

            # Update clipboard
            set_clipboard(rewritten)

            rumps.notification(
                APP_NAME,
                "Done!",
                "Rewritten text is on your clipboard. Paste with Cmd+V.",
            )
        except EnvironmentError as e:
            rumps.notification(APP_NAME, "Configuration Error", str(e))
        except Exception as e:
            rumps.notification(APP_NAME, "Error", str(e)[:200])
        finally:
            self._busy = False
            self.title = TITLE_IDLE

    # ----- Global Hotkeys (Option + key) -----

    def _start_hotkeys(self):
        """Register global hotkeys using pynput."""
        try:
            from pynput import keyboard

            def on_press(key):
                if not self._hotkeys_active:
                    return
                try:
                    # Check if Option (Alt) is held with a character key
                    if hasattr(key, "char") and key.char:
                        # pynput reports Option+key as special chars on macOS.
                        # We handle this via the vk (virtual key) code instead.
                        pass
                except AttributeError:
                    pass

            def on_hotkey(mode):
                """Triggered when a hotkey combination is pressed."""
                if self._hotkeys_active:
                    self._do_rewrite(mode)

            # Register Option+<key> combinations
            hotkeys = {}
            for key_char, mode in HOTKEY_MAP.items():
                combo = f"<alt>+{key_char}"
                hotkeys[combo] = lambda m=mode: on_hotkey(m)

            self._hotkey_listener = keyboard.GlobalHotKeys(hotkeys)
            self._hotkey_listener.daemon = True
            self._hotkey_listener.start()
            self._hotkeys_active = True

        except ImportError:
            # pynput not installed — hotkeys disabled, menu still works
            self._hotkeys_active = False
            print(
                "NOTE: 'pynput' not installed. Global hotkeys disabled.\n"
                "Install with: pip3 install pynput\n"
                "Menu bar click-to-rewrite still works."
            )
        except Exception as e:
            self._hotkeys_active = False
            print(f"NOTE: Could not register global hotkeys: {e}")

    def _stop_hotkeys(self):
        """Stop the global hotkey listener."""
        if self._hotkey_listener:
            self._hotkey_listener.stop()
            self._hotkey_listener = None
        self._hotkeys_active = False

    # ----- Menu callbacks -----

    def _toggle_hotkeys(self, sender):
        """Toggle global hotkeys on/off."""
        if self._hotkeys_active:
            self._stop_hotkeys()
            sender.title = "Global Hotkeys: OFF"
            rumps.notification(APP_NAME, "Hotkeys Disabled", "Use the menu bar to rewrite.")
        else:
            self._start_hotkeys()
            if self._hotkeys_active:
                sender.title = "Global Hotkeys: ON"
                rumps.notification(APP_NAME, "Hotkeys Enabled", "Option+R/P/C/G/W active.")
            else:
                rumps.notification(
                    APP_NAME,
                    "Hotkeys Unavailable",
                    "Install pynput: pip3 install pynput",
                )

    def _open_config(self, sender):
        """Open config.json in the default text editor."""
        config_path = SCRIPT_DIR / "config.json"
        if not config_path.exists():
            # Create default config if it doesn't exist
            from rewrite import save_default_config

            save_default_config()
        subprocess.run(["open", str(config_path)])

    def _reload_config(self, sender):
        """Reload configuration from disk."""
        self.config = load_config()
        rumps.notification(APP_NAME, "Config Reloaded", "Using updated settings.")

    def _show_about(self, sender):
        """Show about dialog."""
        rumps.alert(
            title="Clipboard Rewriter",
            message=(
                "A macOS menu bar tool that rewrites your clipboard\n"
                "contents using OpenAI.\n\n"
                "Modes: Default, Professional, Casual, Fix Grammar, AI Prompt\n\n"
                "Hotkeys: Option + R / P / C / G / W\n\n"
                f"Config: {SCRIPT_DIR / 'config.json'}"
            ),
            ok="OK",
        )

    def _quit(self, sender):
        """Clean shutdown."""
        self._stop_hotkeys()
        rumps.quit_application()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    """Launch the menu bar application."""
    # Verify API key early
    if not os.environ.get("OPENAI_API_KEY"):
        # Check shell profiles for the key
        for profile in ["~/.zshrc", "~/.bash_profile", "~/.bashrc"]:
            expanded = os.path.expanduser(profile)
            if os.path.exists(expanded):
                try:
                    with open(expanded) as f:
                        for line in f:
                            if line.strip().startswith("export OPENAI_API_KEY="):
                                # Extract the key value
                                val = line.split("=", 1)[1].strip().strip("'\"")
                                os.environ["OPENAI_API_KEY"] = val
                                break
                except Exception:
                    pass
            if os.environ.get("OPENAI_API_KEY"):
                break

    if not os.environ.get("OPENAI_API_KEY"):
        rumps.notification(
            APP_NAME,
            "API Key Missing",
            "Set OPENAI_API_KEY in ~/.zshrc and restart the app.",
        )
        # Still launch — user can set the key and it will be picked up on next rewrite

    app = ClipboardRewriterApp()
    app.run()


if __name__ == "__main__":
    main()
