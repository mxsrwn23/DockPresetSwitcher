<div align="center">
  <h1>DockPresetSwitcher</h1>

  <p><strong>Save your Dock layout. Switch it back in a keystroke.</strong></p>

  <p>
    A macOS menu bar app that saves your current Dock (apps, folders, order)
    as a named preset and switches between presets with a click or a global
    hotkey.
  </p>

  <p>
    <img src="https://img.shields.io/badge/Platform-macOS-blue" alt="Platform: macOS">
    <img src="https://img.shields.io/badge/macOS-13%2B-orange" alt="macOS 13+">
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="License: MIT"></a>
  </p>
</div>

---

## Contents

- [Features](#features)
- [Install as a Standalone App](#install-as-a-standalone-app)
- [Build & Run](#build--run)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Known Limitations](#known-limitations)
- [License](#license)

---

## Features

- **Unlimited presets** – save, apply, and delete as many Dock layouts as you want.
- **Global hotkeys** – assign a shortcut per preset, works even while the app is in the background.
- **Menu bar only** – no Dock icon, no Cmd+Tab entry, stays out of your way.
- **No network, no dependencies** – pure Foundation/AppKit/Carbon, nothing phones home.

---

## Install as a Standalone App

```bash
./Scripts/build-app.sh
cp -R dist/DockPresetSwitcher.app /Applications/
```

Builds an ad-hoc signed `.app` bundle, no terminal needed to run it afterwards.

To also start it automatically at login:

```bash
./Scripts/install-login-item.sh
```

This installs a LaunchAgent at `~/Library/LaunchAgents/de.maxsauerwein.dockpresetswitcher.plist`. To remove it:

```bash
launchctl unload ~/Library/LaunchAgents/de.maxsauerwein.dockpresetswitcher.plist
rm ~/Library/LaunchAgents/de.maxsauerwein.dockpresetswitcher.plist
```

---

## Build & Run

Requires the Xcode Command Line Tools (`xcode-select -p` should print a path).

```bash
swift run
```

---

## Usage

1. Set up your Dock the way you want to save it.
2. Menu bar icon → **"Save Current Dock as Preset…"** → give it a name.
3. Click a preset in the menu to apply it anytime.
4. Preset submenu → **"Assign Shortcut…"** → press a key combo (needs at
   least one modifier: ⌘/⌥/⌃/⇧). The shortcut then switches the Dock
   globally, even while another app is in the foreground.

---

## How It Works

| Aspect | Detail |
| :--- | :--- |
| **Storage** | `~/Library/Application Support/DockPresetSwitcher/` |
| **Presets** | `Presets/<name>.plist`, a full export of the `com.apple.dock` preferences domain |
| **Hotkeys** | `hotkeys.json`, maps preset name → shortcut |
| **Applying a preset** | `defaults import com.apple.dock <preset>.plist`, then `killall Dock` |
| **Global shortcuts** | Carbon `RegisterEventHotKey`/`InstallEventHandler`, needs no Accessibility or Input Monitoring permission |

---

## Known Limitations

- Only ad-hoc signed (`codesign --sign -`), no Developer ID certificate. Distributing to other machines would need a real certificate and notarization, or Gatekeeper will warn.
- Presets only capture what `defaults export com.apple.dock` returns (Dock items, size, position, etc.), not window or Space state.
- Switching presets restarts Dock.app, which causes a brief flicker. This is a macOS limitation, not something the app can avoid.

---

## License

Released under the [MIT License](LICENSE).
