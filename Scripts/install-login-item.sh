#!/bin/bash
set -euo pipefail

APP_PATH="/Applications/DockPresetSwitcher.app"
BUNDLE_ID="de.maxsauerwein.dockpresetswitcher"
PLIST_PATH="$HOME/Library/LaunchAgents/${BUNDLE_ID}.plist"

if [ ! -d "$APP_PATH" ]; then
    echo "Fehler: $APP_PATH nicht gefunden. Erst Scripts/build-app.sh ausführen und die App nach /Applications kopieren." >&2
    exit 1
fi

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${BUNDLE_ID}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${APP_PATH}/Contents/MacOS/DockPresetSwitcher</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
PLIST

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo "==> Login Item installiert: $PLIST_PATH"
echo "==> DockPresetSwitcher startet ab jetzt automatisch beim Login."
