#!/bin/bash
# -------------------------------------------------------------------
# Clipboard Rewriter — One-time setup
# -------------------------------------------------------------------
# This script:
#   1. Installs the openai Python package if needed
#   2. Makes scripts executable
#   3. Creates macOS Automator Quick Actions for hotkey binding
# -------------------------------------------------------------------

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICES_DIR="$HOME/Library/Services"

echo "🔧 Clipboard Rewriter — Setup"
echo "=============================="
echo ""

# ---------------------------------------------------------------
# 1. Check / install openai
# ---------------------------------------------------------------
echo "📦 Checking Python dependencies..."
if python3 -c "import openai" 2>/dev/null; then
    echo "   ✅ openai is already installed"
else
    echo "   📥 Installing openai..."
    pip3 install --user openai
    echo "   ✅ openai installed"
fi

# ---------------------------------------------------------------
# 2. Make scripts executable
# ---------------------------------------------------------------
echo ""
echo "🔑 Making scripts executable..."
chmod +x "$SCRIPT_DIR/rewrite.py"
chmod +x "$SCRIPT_DIR/rewrite.sh"
echo "   ✅ Done"

# ---------------------------------------------------------------
# 3. Check OPENAI_API_KEY
# ---------------------------------------------------------------
echo ""
if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  OPENAI_API_KEY is NOT set in your current shell."
    echo "   Add this to your ~/.zshrc (or ~/.bash_profile):"
    echo ""
    echo "     export OPENAI_API_KEY='sk-...your-key-here...'"
    echo ""
    echo "   Then run:  source ~/.zshrc"
else
    echo "🔑 OPENAI_API_KEY is set ✅"
fi

# ---------------------------------------------------------------
# 4. Create Automator Quick Actions
# ---------------------------------------------------------------
echo ""
echo "🤖 Creating Automator Quick Actions..."

create_quick_action() {
    local name="$1"
    local mode="$2"
    local workflow_dir="$SERVICES_DIR/${name}.workflow/Contents"

    mkdir -p "$workflow_dir"

    cat > "$workflow_dir/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>${name}</string>
            </dict>
            <key>NSMessage</key>
            <string>runWorkflowAsService</string>
        </dict>
    </array>
</dict>
</plist>
PLIST

    cat > "$workflow_dir/document.wflow" << WFLOW
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>523</string>
    <key>AMApplicationVersion</key>
    <string>2.10</string>
    <key>AMDocumentVersion</key>
    <string>2</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>AMAccepts</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Optional</key>
                    <true/>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.string</string>
                    </array>
                </dict>
                <key>AMActionVersion</key>
                <string>2.0.3</string>
                <key>AMApplication</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>AMCategory</key>
                <string>AMCategoryUtilities</string>
                <key>AMIconName</key>
                <string>Automator</string>
                <key>AMKeywords</key>
                <array>
                    <string>Shell</string>
                    <string>Script</string>
                </array>
                <key>AMName</key>
                <string>Run Shell Script</string>
                <key>AMProvides</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.string</string>
                    </array>
                </dict>
                <key>AMTag</key>
                <string>AMTagUtilities</string>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run Shell Script.action</string>
                <key>ActionName</key>
                <string>Run Shell Script</string>
                <key>ActionParameters</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <string>${SCRIPT_DIR}/rewrite.sh ${mode}</string>
                    <key>CheckedForUserDefaultShell</key>
                    <true/>
                    <key>inputMethod</key>
                    <integer>1</integer>
                    <key>shell</key>
                    <string>/bin/bash</string>
                    <key>source</key>
                    <string></string>
                </dict>
                <key>BundleIdentifier</key>
                <string>com.apple.RunShellScript</string>
                <key>CFBundleVersion</key>
                <string>2.0.3</string>
                <key>CanShowSelectedItemsWhenRun</key>
                <false/>
                <key>CanShowWhenRun</key>
                <true/>
                <key>Category</key>
                <array>
                    <string>AMCategoryUtilities</string>
                </array>
                <key>Class Name</key>
                <string>RunShellScriptAction</string>
                <key>InputUUID</key>
                <string>$(uuidgen)</string>
                <key>Keywords</key>
                <array>
                    <string>Shell</string>
                    <string>Script</string>
                </array>
                <key>OutputUUID</key>
                <string>$(uuidgen)</string>
                <key>UUID</key>
                <string>$(uuidgen)</string>
                <key>UnlocalizedApplications</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>arguments</key>
                <dict>
                    <key>0</key>
                    <dict>
                        <key>default value</key>
                        <string>/bin/bash</string>
                        <key>name</key>
                        <string>shell</string>
                        <key>required</key>
                        <string>YES</string>
                        <key>type</key>
                        <integer>8</integer>
                    </dict>
                    <key>1</key>
                    <dict>
                        <key>default value</key>
                        <string></string>
                        <key>name</key>
                        <string>source</string>
                        <key>required</key>
                        <string>NO</string>
                        <key>type</key>
                        <integer>8</integer>
                    </dict>
                </dict>
                <key>isViewVisible</key>
                <true/>
                <key>location</key>
                <string>529.000000:620.000000</string>
                <key>nibPath</key>
                <string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
            </dict>
        </dict>
    </array>
    <key>connectors</key>
    <dict/>
    <key>workflowMetaData</key>
    <dict>
        <key>workflowTypeIdentifier</key>
        <string>com.apple.Automator.servicesMenu</string>
    </dict>
</dict>
</plist>
WFLOW

    echo "   ✅ Created: ${name}"
}

# Create Quick Actions for each mode
create_quick_action "Clipboard Rewriter"              "default"
create_quick_action "Clipboard Rewriter (Professional)" "pro"
create_quick_action "Clipboard Rewriter (Casual)"      "cas"
create_quick_action "Clipboard Rewriter (Fix Grammar)"  "fix"

# ---------------------------------------------------------------
# 5. Final instructions
# ---------------------------------------------------------------
echo ""
echo "=============================="
echo "✅ Setup complete!"
echo ""
echo "📌 NEXT STEP — Assign a keyboard shortcut:"
echo ""
echo "   1. Open System Settings → Keyboard → Keyboard Shortcuts → Services"
echo "      (on older macOS: System Preferences → Keyboard → Shortcuts → Services)"
echo ""
echo "   2. Scroll to 'General' section"
echo ""
echo "   3. Find these Quick Actions and assign hotkeys:"
echo "      • Clipboard Rewriter              → e.g. ⌥R  (Option+R)"
echo "      • Clipboard Rewriter (Professional) → e.g. ⌥P"
echo "      • Clipboard Rewriter (Casual)       → e.g. ⌥C"  
echo "      • Clipboard Rewriter (Fix Grammar)  → e.g. ⌥G"
echo ""
echo "   4. Done! Now copy text, press your hotkey, and paste the rewritten version."
echo ""
echo "💡 TIP: You can also run directly from terminal:"
echo "   ${SCRIPT_DIR}/rewrite.sh           # default rewrite"
echo "   ${SCRIPT_DIR}/rewrite.sh pro       # professional tone"
echo "   ${SCRIPT_DIR}/rewrite.sh cas       # casual tone"
echo "   ${SCRIPT_DIR}/rewrite.sh fix       # fix grammar only"
echo ""
echo "⚙️  Config file: ${SCRIPT_DIR}/config.json"
echo "   Edit it to change the model, temperature, or system prompts."
