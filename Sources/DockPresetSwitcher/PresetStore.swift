//
//  PresetStore.swift
//  DockPresetSwitcher
//
//  Created by Max Sauerwein on 31.08.26.
//

import Foundation
import Carbon.HIToolbox

/// A global shortcut assigned to a preset. `modifiers` uses the Carbon modifier
/// constants (cmdKey, optionKey, controlKey, shiftKey).
struct HotkeyConfig: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    /// Human readable form, e.g. "⌘⌥1"
    var displayString: String {
        var symbols = ""
        if modifiers & UInt32(controlKey) != 0 { symbols += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { symbols += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { symbols += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { symbols += "⌘" }
        symbols += KeyCodeTranslator.characterFor(keyCode: keyCode) ?? "?"
        return symbols
    }
}

/// Manages presets (saved Dock configurations) and their shortcut assignments
/// under ~/Library/Application Support/DockPresetSwitcher.
enum PresetStore {
    private static let fileManager = FileManager.default

    static var baseDirectory: URL = {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("DockPresetSwitcher", isDirectory: true)
    }()

    static var presetsDirectory: URL {
        baseDirectory.appendingPathComponent("Presets", isDirectory: true)
    }

    private static var hotkeysFileURL: URL {
        baseDirectory.appendingPathComponent("hotkeys.json")
    }

    static func ensureDirectoriesExist() {
        try? fileManager.createDirectory(at: presetsDirectory, withIntermediateDirectories: true)
    }

    static func presetFileURL(for name: String) -> URL {
        presetsDirectory.appendingPathComponent("\(name).plist")
    }

    static func listPresetNames() -> [String] {
        ensureDirectoriesExist()
        guard let files = try? fileManager.contentsOfDirectory(at: presetsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .filter { $0.pathExtension == "plist" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    static func presetExists(named name: String) -> Bool {
        fileManager.fileExists(atPath: presetFileURL(for: name).path)
    }

    @discardableResult
    static func deletePreset(named name: String) -> Bool {
        let didDelete = (try? fileManager.removeItem(at: presetFileURL(for: name))) != nil
        removeHotkey(for: name)
        return didDelete
    }

    // MARK: - Hotkeys

    static func loadHotkeys() -> [String: HotkeyConfig] {
        guard let data = try? Data(contentsOf: hotkeysFileURL) else { return [:] }
        return (try? JSONDecoder().decode([String: HotkeyConfig].self, from: data)) ?? [:]
    }

    static func saveHotkeys(_ hotkeys: [String: HotkeyConfig]) {
        ensureDirectoriesExist()
        guard let data = try? JSONEncoder().encode(hotkeys) else { return }
        try? data.write(to: hotkeysFileURL, options: .atomic)
    }

    static func setHotkey(_ config: HotkeyConfig, for presetName: String) {
        var hotkeys = loadHotkeys()
        hotkeys[presetName] = config
        saveHotkeys(hotkeys)
    }

    static func removeHotkey(for presetName: String) {
        var hotkeys = loadHotkeys()
        guard hotkeys.removeValue(forKey: presetName) != nil else { return }
        saveHotkeys(hotkeys)
    }
}
