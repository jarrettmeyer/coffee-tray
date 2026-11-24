// Renders the ☕ emoji (same glyph as the menu bar icon) into an .iconset
// directory. Usage: swift scripts/make-icon.swift <output.iconset>
import AppKit

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.iconset>\n".utf8))
    exit(1)
}
let outDir = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// (point size, scale) pairs required by iconutil.
let variants: [(Int, Int)] = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2),
                              (256, 1), (256, 2), (512, 1), (512, 2)]

for (points, scale) in variants {
    let px = points * scale
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ), let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("could not create bitmap context")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let str = NSAttributedString(
        string: "☕",
        attributes: [.font: NSFont.systemFont(ofSize: CGFloat(px) * 0.8)]
    )
    let size = str.size()
    str.draw(at: NSPoint(x: (CGFloat(px) - size.width) / 2,
                         y: (CGFloat(px) - size.height) / 2))

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("could not encode PNG")
    }
    let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
    try png.write(to: URL(fileURLWithPath: outDir).appendingPathComponent(name))
}
