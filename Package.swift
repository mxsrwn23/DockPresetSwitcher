// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DockPresetSwitcher",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "DockPresetSwitcher",
            path: "Sources/DockPresetSwitcher"
        )
    ]
)
