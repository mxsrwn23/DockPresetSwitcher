//
//  main.swift
//  DockPresetSwitcher
//
//  Created by Max Sauerwein on 31.08.26.
//

import Cocoa

// App entry point. Sets up the delegate and starts the run loop.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// .accessory keeps this a menu bar only app, no Dock icon, no Cmd+Tab entry.
app.setActivationPolicy(.accessory)
app.run()
