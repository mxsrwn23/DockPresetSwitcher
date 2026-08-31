//
//  HotkeyManager.swift
//  DockPresetSwitcher
//
//  Created by Max Sauerwein on 31.08.26.
//

import Carbon.HIToolbox
import Cocoa

/// Registers global keyboard shortcuts through the Carbon Event Manager API
/// (RegisterEventHotKey). This works system wide and does not require
/// Accessibility or Input Monitoring permission.
final class HotkeyManager {
    static let shared = HotkeyManager()

    typealias TriggerHandler = (_ presetName: String) -> Void

    private var triggerHandler: TriggerHandler?
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var idToPresetName: [UInt32: String] = [:]
    private var nextHotKeyID: UInt32 = 1

    private static let signature: OSType = {
        var result: UInt32 = 0
        for byte in "DPS1".utf8.prefix(4) {
            result = (result << 8) + UInt32(byte)
        }
        return result
    }()

    private init() {}

    /// Call this once on app start.
    func start(onTrigger: @escaping TriggerHandler) {
        triggerHandler = onTrigger

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // This is a plain C callback so it can't capture self. userData carries
        // self as an opaque pointer instead, which lets us call dispatch below.
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData in
                guard let eventRef, let userData else { return noErr }
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.dispatch(id: hotKeyID.id)
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        reloadAllFromStore()
    }

    private func dispatch(id: UInt32) {
        guard let presetName = idToPresetName[id] else { return }
        triggerHandler?(presetName)
    }

    /// Removes all registered shortcuts and reloads them from PresetStore.
    func reloadAllFromStore() {
        unregisterAll()
        for (presetName, config) in PresetStore.loadHotkeys() {
            register(presetName: presetName, config: config)
        }
    }

    @discardableResult
    private func register(presetName: String, config: HotkeyConfig) -> Bool {
        let id = nextHotKeyID
        nextHotKeyID += 1

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        let status = RegisterEventHotKey(
            config.keyCode,
            config.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let ref = hotKeyRef else { return false }
        hotKeyRefs[id] = ref
        idToPresetName[id] = presetName
        return true
    }

    private func unregisterAll() {
        for ref in hotKeyRefs.values {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        idToPresetName.removeAll()
        nextHotKeyID = 1
    }
}
