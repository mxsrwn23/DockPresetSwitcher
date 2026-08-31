//
//  HotkeyCapturePanel.swift
//  DockPresetSwitcher
//
//  Created by Max Sauerwein on 31.08.26.
//

import Carbon.HIToolbox
import Cocoa

/// Shows a small panel that captures the user's next key press as a candidate
/// for a global shortcut.
final class HotkeyCapturePanel {
    private var panel: NSPanel?
    private var localMonitor: Any?
    private var completion: ((HotkeyConfig?) -> Void)?

    static let shared = HotkeyCapturePanel()

    private init() {}

    func present(for presetName: String, completion: @escaping (HotkeyConfig?) -> Void) {
        self.completion = completion

        let label = NSTextField(labelWithString: "Drücke die gewünschte Tastenkombination für \u{201C}\(presetName)\u{201D}\n(Esc zum Abbrechen)")
        label.alignment = .center
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 2
        label.frame = NSRect(x: 20, y: 20, width: 300, height: 50)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 90),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Shortcut zuweisen"
        panel.center()
        panel.contentView?.addSubview(label)
        panel.isFloatingPanel = true
        panel.level = .modalPanel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return nil // swallow the event instead of passing it on
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        defer { dismiss() }

        if event.keyCode == UInt16(kVK_Escape) {
            completion?(nil)
            return
        }

        var carbonModifiers: UInt32 = 0
        if event.modifierFlags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if event.modifierFlags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if event.modifierFlags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        if event.modifierFlags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }

        guard carbonModifiers != 0 else {
            // No modifier means no usable global shortcut, so keep waiting.
            presentAgainAfterInvalidAttempt()
            return
        }

        let config = HotkeyConfig(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers)
        completion?(config)
    }

    private func presentAgainAfterInvalidAttempt() {
        // Keep the panel open so the user can try again with a modifier key.
        panel?.makeKeyAndOrderFront(nil)
    }

    private func dismiss() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        panel?.orderOut(nil)
        panel = nil
        completion = nil
    }
}
