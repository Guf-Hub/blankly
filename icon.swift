// Рисует иконку приложения 1024×1024 в PNG. Запуск: swift icon.swift <вариант a|b|c> <out.png>
import AppKit

let args = CommandLine.arguments
let variant = args.count > 1 ? args[1] : "a"
let out = args.count > 2 ? args[2] : "icon.png"

let S: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

func c(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}
func shadow(_ blur: CGFloat, _ y: CGFloat, _ a: CGFloat) {
    let s = NSShadow(); s.shadowBlurRadius = blur; s.shadowOffset = NSSize(width: 0, height: -y)
    s.shadowColor = NSColor.black.withAlphaComponent(a); s.set()
}

// Плитка по сетке macOS: 824×824, скругление ~185
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
let palettes: [String: (UInt32, UInt32, UInt32)] = [
    "a": (0x4FACFE, 0x2B5BE8, 0x34C759), // голубой → синий, зелёный плюс
    "b": (0x3A3D46, 0x1C1D22, 0xFF9F0A), // графит, оранжевый плюс
    "c": (0xB26BFF, 0xFF5E8A, 0x1C1D22), // фиолетовый → розовый, тёмный плюс
]
let (top, bottom, accent) = palettes[variant] ?? palettes["a"]!

NSGraphicsContext.saveGraphicsState()
shadow(30, 14, 0.30)
c(bottom).setFill(); tilePath.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: c(top), ending: c(bottom))!.draw(in: tilePath, angle: -90)
// лёгкий блик сверху
NSGraphicsContext.saveGraphicsState()
tilePath.addClip()
NSGradient(starting: NSColor.white.withAlphaComponent(0.18), ending: .clear)!
    .draw(in: NSRect(x: 100, y: 524, width: 824, height: 400), angle: -90)
NSGraphicsContext.restoreGraphicsState()

// Лист с загнутым углом
func page(_ r: NSRect, fold: CGFloat, fill: NSColor) {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: r.minX + 28, y: r.minY))
    p.line(to: NSPoint(x: r.maxX - 28, y: r.minY))
    p.curve(to: NSPoint(x: r.maxX, y: r.minY + 28), controlPoint1: NSPoint(x: r.maxX - 12, y: r.minY), controlPoint2: NSPoint(x: r.maxX, y: r.minY + 12))
    p.line(to: NSPoint(x: r.maxX, y: r.maxY - fold))
    p.line(to: NSPoint(x: r.maxX - fold, y: r.maxY))
    p.line(to: NSPoint(x: r.minX + 28, y: r.maxY))
    p.curve(to: NSPoint(x: r.minX, y: r.maxY - 28), controlPoint1: NSPoint(x: r.minX + 12, y: r.maxY), controlPoint2: NSPoint(x: r.minX, y: r.maxY - 12))
    p.line(to: NSPoint(x: r.minX, y: r.minY + 28))
    p.curve(to: NSPoint(x: r.minX + 28, y: r.minY), controlPoint1: NSPoint(x: r.minX, y: r.minY + 12), controlPoint2: NSPoint(x: r.minX + 12, y: r.minY))
    p.close()
    NSGraphicsContext.saveGraphicsState(); shadow(36, 18, 0.28); fill.setFill(); p.fill(); NSGraphicsContext.restoreGraphicsState()
    // загиб
    let f = NSBezierPath()
    f.move(to: NSPoint(x: r.maxX - fold, y: r.maxY))
    f.line(to: NSPoint(x: r.maxX - fold, y: r.maxY - fold + 22))
    f.curve(to: NSPoint(x: r.maxX - fold + 22, y: r.maxY - fold), controlPoint1: NSPoint(x: r.maxX - fold, y: r.maxY - fold + 8), controlPoint2: NSPoint(x: r.maxX - fold + 8, y: r.maxY - fold))
    f.line(to: NSPoint(x: r.maxX, y: r.maxY - fold))
    f.close()
    c(0xDCE3EE).setFill(); f.fill()
    // строки текста
    c(0xC9D2DF).setFill()
    let lx = r.minX + 64
    for (i, w) in [0.62, 0.74, 0.5].enumerated() {
        NSBezierPath(roundedRect: NSRect(x: lx, y: r.maxY - fold - 70 - CGFloat(i) * 62, width: (r.width - 128) * w, height: 26),
                     xRadius: 13, yRadius: 13).fill()
    }
}

if variant == "c" {
    page(NSRect(x: 300, y: 250, width: 380, height: 480), fold: 110, fill: c(0xF3F5F9))
}
let pr = variant == "c" ? NSRect(x: 360, y: 210, width: 380, height: 480) : NSRect(x: 307, y: 220, width: 410, height: 540)
page(pr, fold: 120, fill: .white)

// Кружок с плюсом
let d: CGFloat = 270
let cr = NSRect(x: pr.maxX - d * 0.62, y: pr.minY - d * 0.28, width: d, height: d)
NSGraphicsContext.saveGraphicsState(); shadow(30, 12, 0.32)
c(accent).setFill(); NSBezierPath(ovalIn: cr).fill()
NSGraphicsContext.restoreGraphicsState()
NSColor.white.setStroke()
NSColor.white.setFill()
let bar: CGFloat = 34, len: CGFloat = 136
NSBezierPath(roundedRect: NSRect(x: cr.midX - len / 2, y: cr.midY - bar / 2, width: len, height: bar), xRadius: bar / 2, yRadius: bar / 2).fill()
NSBezierPath(roundedRect: NSRect(x: cr.midX - bar / 2, y: cr.midY - len / 2, width: bar, height: len), xRadius: bar / 2, yRadius: bar / 2).fill()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("ok", out)
