//
//  AppDelegate.swift
//  DockPresetSwitcher
//
//  Created by Max Sauerwein on 31.08.26.
//

import Cocoa

/// Owns the menu bar icon and wires up user actions to PresetStore, DockManager
/// and HotkeyManager.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        PresetStore.ensureDirectoriesExist()

        // isTemplate makes the icon adapt to light and dark mode automatically.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "dock.rectangle", accessibilityDescription: "DockPresetSwitcher")
        statusItem.button?.image?.isTemplate = true

        rebuildMenu()

        // Start listening for global shortcuts and apply the matching preset when one fires.
        HotkeyManager.shared.start { [weak self] presetName in
            self?.applyPreset(named: presetName)
        }
    }

    // MARK: - Menu

    /// Rebuilds the whole status bar menu from scratch. Called again after every
    /// change so the menu always reflects the current state.
    private func rebuildMenu() {
        let menu = NSMenu()
        let hotkeys = PresetStore.loadHotkeys()
        let presetNames = PresetStore.listPresetNames()

        if presetNames.isEmpty {
            let emptyItem = NSMenuItem(title: "Keine Presets gespeichert", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for name in presetNames {
                let title = hotkeys[name].map { "\(name)  (\($0.displayString))" } ?? name
                let item = NSMenuItem(title: title, action: #selector(applyPresetMenuAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = name

                let submenu = NSMenu()
                let assignItem = NSMenuItem(title: "Shortcut zuweisen…", action: #selector(assignHotkeyMenuAction(_:)), keyEquivalent: "")
                assignItem.target = self
                assignItem.representedObject = name
                submenu.addItem(assignItem)

                if hotkeys[name] != nil {
                    let removeShortcutItem = NSMenuItem(title: "Shortcut entfernen", action: #selector(removeHotkeyMenuAction(_:)), keyEquivalent: "")
                    removeShortcutItem.target = self
                    removeShortcutItem.representedObject = name
                    submenu.addItem(removeShortcutItem)
                }

                submenu.addItem(.separator())
                let deleteItem = NSMenuItem(title: "Preset löschen", action: #selector(deletePresetMenuAction(_:)), keyEquivalent: "")
                deleteItem.target = self
                deleteItem.representedObject = name
                submenu.addItem(deleteItem)

                item.submenu = submenu
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        let saveItem = NSMenuItem(title: "Aktuelles Dock als Preset speichern…", action: #selector(saveNewPresetMenuAction), keyEquivalent: "n")
        saveItem.target = self
        menu.addItem(saveItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Beenden", action: #selector(quitMenuAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func applyPresetMenuAction(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        applyPreset(named: name)
    }

    /// DockManager handles the actual import and Dock restart.
    private func applyPreset(named name: String) {
        do {
            try DockManager.applyPreset(named: name)
        } catch {
            showError(error)
        }
    }

    /// Asks for a name via an alert and saves the current Dock layout under it.
    @objc private func saveNewPresetMenuAction() {
        let alert = NSAlert()
        alert.messageText = "Neues Dock-Preset speichern"
        alert.informativeText = "Name für das Preset:"
        alert.addButton(withTitle: "Speichern")
        alert.addButton(withTitle: "Abbrechen")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        input.placeholderString = "z.B. Arbeit"
        alert.accessoryView = input
        alert.window.initialFirstResponder = input

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        do {
            try DockManager.savePreset(named: name)
            rebuildMenu()
        } catch {
            showError(error)
        }
    }

    /// Deletes a preset after confirmation, along with any shortcut assigned to it.
    @objc private func deletePresetMenuAction(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }

        let alert = NSAlert()
        alert.messageText = "Preset \u{201C}\(name)\u{201D} löschen?"
        alert.addButton(withTitle: "Löschen")
        alert.addButton(withTitle: "Abbrechen")
        alert.alertStyle = .warning
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        PresetStore.deletePreset(named: name)
        HotkeyManager.shared.reloadAllFromStore()
        rebuildMenu()
    }

    /// Opens the capture panel so the user can assign a new shortcut by pressing keys.
    @objc private func assignHotkeyMenuAction(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        HotkeyCapturePanel.shared.present(for: name) { [weak self] config in
            guard let self else { return }
            if let config {
                PresetStore.setHotkey(config, for: name)
                HotkeyManager.shared.reloadAllFromStore()
                self.rebuildMenu()
            }
        }
    }

    @objc private func removeHotkeyMenuAction(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        PresetStore.removeHotkey(for: name)
        HotkeyManager.shared.reloadAllFromStore()
        rebuildMenu()
    }

    @objc private func quitMenuAction() {
        NSApp.terminate(nil)
    }

    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Fehler"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.runModal()
    }
}
