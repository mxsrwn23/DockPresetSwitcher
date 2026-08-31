//
//  KeyCodeTranslator.swift
//  DockPresetSwitcher
//
//  Created by Max Sauerwein on 31.08.26.
//

import Carbon.HIToolbox
import Foundation

/// Translates a virtual macOS key code into a displayable character, taking
/// the current keyboard layout into account.
enum KeyCodeTranslator {
    static func characterFor(keyCode: UInt32) -> String? {
        // Special keys don't get a useful character from UCKeyTranslate, so use fixed symbols.
        switch Int(keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "⏎"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default:
            break
        }

        // Translate everything else through the active keyboard layout, so a
        // QWERTZ keyboard shows the correct character too.
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let layoutDataPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }

        let layoutData = Unmanaged<CFData>.fromOpaque(layoutDataPointer).takeUnretainedValue() as Data
        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0

        let result = layoutData.withUnsafeBytes { rawBuffer -> OSStatus in
            guard let keyboardLayoutPtr = rawBuffer.bindMemory(to: UCKeyboardLayout.self).baseAddress else {
                return errSecParam
            }
            return UCKeyTranslate(
                keyboardLayoutPtr,
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )
        }

        guard result == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length).uppercased()
    }
}
