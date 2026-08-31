// Renders a rounded-square app icon (blue gradient + dock.rectangle symbol)
// at every size macOS expects, and writes them into an .iconset folder.
// Usage: swift Scripts/generate-icon.swift <output.iconset>

import AppKit

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

let outputDir = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

func renderIcon(pixelSize: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let size = CGFloat(pixelSize)
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.2237 // matches macOS's rounded-square icon shape
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    path.addClip()

    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 0.32, green: 0.58, blue: 1.0, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.05, green: 0.22, blue: 0.58, alpha: 1.0)
    )
    gradient?.draw(in: path, angle: -90)

    if let base = NSImage(systemSymbolName: "dock.rectangle", accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: size * 0.52, weight: .medium)
            .applying(.init(paletteColors: [.white]))
        if let symbol = base.withSymbolConfiguration(config) {
            let symbolSize = symbol.size
            let symbolRect = NSRect(
                x: (size - symbolSize.width) / 2,
                y: (size - symbolSize.height) / 2,
                width: symbolSize.width,
                height: symbolSize.height
            )
            symbol.draw(in: symbolRect)
        }
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

for entry in sizes {
    let rep = renderIcon(pixelSize: entry.pixels)
    guard let data = rep.representation(using: .png, properties: [:]) else { continue }
    try? data.write(to: outputDir.appendingPathComponent(entry.name))
}

print("Wrote \(sizes.count) icon sizes to \(outputDir.path)")
