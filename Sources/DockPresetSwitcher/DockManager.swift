//
//  DockManager.swift
//  DockPresetSwitcher
//
//  Created by Max Sauerwein on 31.08.26.
//

import Foundation

enum DockManagerError: Error, LocalizedError {
    case exportFailed(String)
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .exportFailed(let message): return "Dock-Export fehlgeschlagen: \(message)"
        case .importFailed(let message): return "Dock-Import fehlgeschlagen: \(message)"
        }
    }
}

/// Reads and writes the whole com.apple.dock preferences domain through the
/// `defaults` CLI tool, so cfprefsd stays in sync. Editing the plist file
/// directly can get overwritten by the running Dock.app.
enum DockManager {
    private static let domain = "com.apple.dock"

    /// Exports the current Dock configuration as plist data.
    static func exportCurrentDock() throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["export", domain, "-"]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: errData, encoding: .utf8) ?? "unbekannter Fehler"
            throw DockManagerError.exportFailed(message)
        }
        return data
    }

    /// Saves the current Dock configuration to disk as a new preset.
    static func savePreset(named name: String) throws {
        let data = try exportCurrentDock()
        let url = PresetStore.presetFileURL(for: name)
        try data.write(to: url, options: .atomic)
    }

    /// Applies a saved preset and restarts Dock.app so the change shows up right away.
    static func applyPreset(named name: String) throws {
        let url = PresetStore.presetFileURL(for: name)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DockManagerError.importFailed("Preset-Datei nicht gefunden: \(url.path)")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["import", domain, url.path]

        let stderr = Pipe()
        process.standardError = stderr
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: errData, encoding: .utf8) ?? "unbekannter Fehler"
            throw DockManagerError.importFailed(message)
        }

        restartDock()
    }

    /// Kills Dock.app. launchd relaunches it automatically, and it then picks up
    /// the freshly imported preferences. The brief flicker is a macOS limitation,
    /// there is no public API to make the Dock reload its prefs live.
    static func restartDock() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]
        try? process.run()
        process.waitUntilExit()
    }
}
