#!/bin/bash
# -------------------------------------------------------------------
# Install keyboard shortcuts using Automator Quick Actions
# -------------------------------------------------------------------

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICES_DIR="$HOME/Library/Services"

echo "🔧 Installing Clipboard Rewriter hotkeys..."
echo ""

create_service() {
    local name="$1"
    local mode="$2"
    local workflow_dir="$SERVICES_DIR/${name}.workflow/Contents"

    mkdir -p "$workflow_dir"

    # Info.plist — required for macOS to register it as a Service
    cat > "$workflow_dir/Info.plist" << 'INFOPLIST'
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
				<string>Quick Action</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
		</dict>
	</array>
</dict>
</plist>
INFOPLIST

    local uuid1 uuid2 uuid3
    uuid1=$(uuidgen)
    uuid2=$(uuidgen)
    uuid3=$(uuidgen)

    # document.wflow — matches the exact format macOS expects
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
				<string>${uuid1}</string>
				<key>Keywords</key>
				<array>
					<string>Shell</string>
					<string>Script</string>
				</array>
				<key>OutputUUID</key>
				<string>${uuid2}</string>
				<key>UUID</key>
				<string>${uuid3}</string>
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

    echo "   ✅ ${name}"
}

# Remove stale workflows first
rm -rf "$SERVICES_DIR/Clipboard Rewrite.workflow"
rm -rf "$SERVICES_DIR/Clipboard Rewrite Professional.workflow"
rm -rf "$SERVICES_DIR/Clipboard Rewrite Casual.workflow"
rm -rf "$SERVICES_DIR/Clipboard Rewrite Fix.workflow"
rm -rf "$SERVICES_DIR/Clipboard Rewrite Prompt.workflow"
rm -rf "$SERVICES_DIR/Clipboard Rewrite Tweet.workflow"

# Create all Quick Actions
create_service "Clipboard Rewrite"              "default"
create_service "Clipboard Rewrite Professional" "pro"
create_service "Clipboard Rewrite Casual"       "cas"
create_service "Clipboard Rewrite Fix"          "fix"
create_service "Clipboard Rewrite Prompt"       "prompt"
create_service "Clipboard Rewrite Tweet"        "tweet"

# Force macOS to reload Services
/System/Library/CoreServices/pbs -update 2>/dev/null || true
killall -HUP pbs 2>/dev/null || true

echo ""
echo "✅ Quick Actions installed!"
echo ""
echo "📌 NOW assign keyboard shortcuts:"
echo ""
echo "   1. Open: System Settings → Keyboard → Keyboard Shortcuts → Services"
echo "   2. Look under 'General' for the Quick Actions"
echo "   3. Assign shortcuts:"
echo "      • Clipboard Rewrite              → ⌥R"
echo "      • Clipboard Rewrite Professional → ⌥P"
echo "      • Clipboard Rewrite Casual       → ⌥C"
echo "      • Clipboard Rewrite Fix          → ⌥G"
echo "      • Clipboard Rewrite Prompt       → ⌥W"
echo "      • Clipboard Rewrite Tweet        → ⌃T"
echo ""
echo "   ⚠️  If they still don't appear, log out and back in once."
echo ""
