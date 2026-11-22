#!/usr/bin/env swift
// Draws the sharing image, 1200 by 630: Encore's icon and name in round Allo over the Studio, on the cream with
// a peach blush, like the page. scripts/images.sh runs it.
//
//     swift scripts/og.swift <AlloVariable.ttf> <studio.png> <icon.png> <out.png>

import AppKit
import CoreText

let args = CommandLine.arguments
guard args.count == 5 else {
    FileHandle.standardError.write(Data("usage: og.swift <AlloVariable.ttf> <studio.png> <icon.png> <out.png>\n".utf8))
    exit(2)
}
let fontURL = URL(fileURLWithPath: args[1])
guard let studio = NSImage(contentsOfFile: args[2]), let icon = NSImage(contentsOfFile: args[3]) else {
    FileHandle.standardError.write(Data("og.swift: can't read the images\n".utf8))
    exit(1)
}
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

func allo(_ size: CGFloat, weight: CGFloat, roundness: CGFloat) -> NSFont {
    func tag(_ s: String) -> UInt32 { s.utf8.reduce(0) { ($0 << 8) | UInt32($1) } }
    let descriptor = CTFontDescriptorCreateWithAttributes([
        kCTFontNameAttribute: "AlloVariable-Regular",
        kCTFontVariationAttribute: [tag("wght"): weight, tag("opsz"): min(max(size, 9), 32), tag("ROND"): roundness] as [UInt32: CGFloat],
    ] as CFDictionary)
    return CTFontCreateWithFontDescriptor(descriptor, size, nil) as NSFont
}
func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let size = CGSize(width: 1200, height: 630)
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = context
let cg = context.cgContext
// y runs down from the top.
cg.translateBy(x: 0, y: size.height)
cg.scaleBy(x: 1, y: -1)
NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)

// Ground: cream, a blush in the top-right corner.
color(0xF3E9D9).setFill()
CGRect(origin: .zero, size: size).fill()
NSGradient(colors: [color(0xFFCBA6, 0.8), color(0xFFCBA6, 0)])!
    .draw(fromCenter: CGPoint(x: 1150, y: 0), radius: 0, toCenter: CGPoint(x: 1150, y: 0), radius: 620, options: [])

// The Studio, in its window, running off the bottom.
let window = CGRect(x: 80, y: 250, width: 1040, height: 1040 * studio.size.height / studio.size.width)
cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: 24), blur: 60, color: color(0x4A3022, 0.35).cgColor)
studio.draw(in: window)
cg.restoreGState()

// The icon, tilted like a sticker, and the name.
cg.saveGState()
cg.translateBy(x: 138, y: 126)
cg.rotate(by: -6 * .pi / 180)
cg.setShadow(offset: CGSize(width: 0, height: 10), blur: 18, color: color(0x4A3022, 0.25).cgColor)
icon.draw(in: CGRect(x: -66, y: -66, width: 132, height: 132))
cg.restoreGState()
NSAttributedString(string: "Encore", attributes: [
    .font: allo(84, weight: 900, roundness: 100), .foregroundColor: color(0x2B1D14), .kern: -3,
]).draw(at: CGPoint(x: 230, y: 52))
NSAttributedString(string: "Local voice AI for the Mac", attributes: [
    .font: allo(29, weight: 500, roundness: 50), .foregroundColor: color(0x6B5546),
]).draw(at: CGPoint(x: 236, y: 150))

NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[4]))
