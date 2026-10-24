// Draws MacKanban's icon artwork: three fanned Cards aging from white through
// amber to red, on the Board's pale blue. Full-bleed 1024 × 1024; make-icon.sh
// puts it on the macOS icon grid. Chosen by Christoph on 2026-10-24 (concept 2).
// Usage: swift scripts/icon-artwork.swift Resources/AppIcon.png
import AppKit

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: icon-artwork.swift <out.png>\n".data(using: .utf8)!)
    exit(1)
}

func rgb(_ hex: Int, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}

let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func roundedRect(_ rect: CGRect, radius: CGFloat, fill: CGColor, stroke: CGColor? = nil, width: CGFloat = 0, shadow: Bool = false) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.saveGState()
    if shadow { context.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: rgb(0x2B3A4F, 0.22)) }
    context.addPath(path)
    context.setFillColor(fill)
    context.fillPath()
    context.restoreGState()
    if let stroke {
        context.addPath(path)
        context.setStrokeColor(stroke)
        context.setLineWidth(width)
        context.strokePath()
    }
}

/// Draws in a Card's frame: rotated by `degrees` around the canvas centre, shifted by `offset`.
func inCard(degrees: CGFloat, offset: CGPoint, _ draw: () -> Void) {
    context.saveGState()
    context.translateBy(x: 512 + offset.x, y: 490 + offset.y)
    context.rotate(by: degrees * .pi / 180)
    context.translateBy(x: -512, y: -490)
    draw()
    context.restoreGState()
}

// The Board's window colours, top to bottom.
let background = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                            colors: [rgb(0xF1F6FC), rgb(0xDDE7F2)] as CFArray, locations: [0, 1])!
context.drawLinearGradient(background, start: CGPoint(x: 0, y: 1024), end: .zero, options: [])

let card = CGRect(x: 262, y: 300, width: 500, height: 380)
let ink = 0x2B3A4F
// Oldest at the back: red, then amber, then a fresh white Card in front.
for (degrees, fill, edge, offset) in [(CGFloat(14), 0xF08A8A, 0xE04848, CGPoint(x: 70, y: 40)),
                                       (6, 0xF6C08A, 0xE8964A, CGPoint(x: 30, y: 10)),
                                       (-3, 0xFFFFFF, 0xDFE1E3, CGPoint(x: -20, y: -30))] {
    inCard(degrees: degrees, offset: offset) {
        roundedRect(card, radius: 64, fill: rgb(fill), stroke: rgb(edge), width: 10, shadow: true)
    }
}
// The front Card's title, a line of notes and its age label.
inCard(degrees: -3, offset: CGPoint(x: -20, y: -30)) {
    roundedRect(CGRect(x: 322, y: 560, width: 300, height: 34), radius: 17, fill: rgb(ink, 0.75))
    roundedRect(CGRect(x: 322, y: 495, width: 220, height: 26), radius: 13, fill: rgb(ink, 0.3))
    roundedRect(CGRect(x: 600, y: 345, width: 110, height: 26), radius: 13, fill: rgb(ink, 0.3))
}

let image = NSBitmapImageRep(cgImage: context.makeImage()!)
try! image.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
