//
// RenderBrandAssets.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//
// Renders the app icon variants and the launch-screen logo into Assets.xcassets.
// Run from the repository root:  swift Tools/RenderBrandAssets.swift
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct RGBA {
    let r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat

    init(hex: UInt32, alpha: CGFloat = 1) {
        r = CGFloat((hex >> 16) & 0xFF) / 255
        g = CGFloat((hex >> 8) & 0xFF) / 255
        b = CGFloat(hex & 0xFF) / 255
        a = alpha
    }

    init(white: CGFloat, alpha: CGFloat = 1) {
        r = white; g = white; b = white; a = alpha
    }

    var cgColor: CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: a) }
}

struct Palette {
    let background: [RGBA]?
    let glow: RGBA
    let cardFillTop: RGBA
    let cardFillBottom: RGBA
    let cardStroke: RGBA
    let arrow: RGBA
    let check: RGBA
    let shadow: RGBA

    static let light = Palette(
        background: [RGBA(hex: 0x2B1B8F), RGBA(hex: 0x5B3DF5), RGBA(hex: 0xB04BE6)],
        glow: RGBA(white: 1, alpha: 0.28),
        cardFillTop: RGBA(white: 1, alpha: 0.30),
        cardFillBottom: RGBA(white: 1, alpha: 0.08),
        cardStroke: RGBA(white: 1, alpha: 0.55),
        arrow: RGBA(white: 1),
        check: RGBA(hex: 0x5EF2C2),
        shadow: RGBA(hex: 0x12063F, alpha: 0.45)
    )

    static let dark = Palette(
        background: [RGBA(hex: 0x0B0820), RGBA(hex: 0x1A1150), RGBA(hex: 0x3A1A6E)],
        glow: RGBA(hex: 0x7B5CFF, alpha: 0.35),
        cardFillTop: RGBA(white: 1, alpha: 0.16),
        cardFillBottom: RGBA(white: 1, alpha: 0.04),
        cardStroke: RGBA(white: 1, alpha: 0.35),
        arrow: RGBA(hex: 0xE9E4FF),
        check: RGBA(hex: 0x5EF2C2),
        shadow: RGBA(white: 0, alpha: 0.6)
    )

    static let tinted = Palette(
        background: [RGBA(white: 0), RGBA(white: 0.04), RGBA(white: 0.08)],
        glow: RGBA(white: 1, alpha: 0.10),
        cardFillTop: RGBA(white: 1, alpha: 0.22),
        cardFillBottom: RGBA(white: 1, alpha: 0.06),
        cardStroke: RGBA(white: 1, alpha: 0.5),
        arrow: RGBA(white: 1),
        check: RGBA(white: 0.78),
        shadow: RGBA(white: 0, alpha: 0)
    )

    static let launch = Palette(
        background: nil,
        glow: RGBA(white: 0, alpha: 0),
        cardFillTop: RGBA(white: 1, alpha: 0.30),
        cardFillBottom: RGBA(white: 1, alpha: 0.08),
        cardStroke: RGBA(white: 1, alpha: 0.55),
        arrow: RGBA(white: 1),
        check: RGBA(hex: 0x5EF2C2),
        shadow: RGBA(hex: 0x12063F, alpha: 0.35)
    )
}

/// All geometry is authored on a 1024 × 1024 canvas with a top-left origin.
enum Glyph {
    static let card = CGRect(x: 232, y: 250, width: 560, height: 600)
    static let center = CGPoint(x: 512, y: 572)
    static let bounds = CGRect(x: 200, y: 190, width: 624, height: 700)

    static func draw(in context: CGContext, palette: Palette) {
        drawCard(in: context, palette: palette)
        drawTabs(in: context, palette: palette)
        drawRenewArrow(in: context, palette: palette)
        drawCheck(in: context, palette: palette)
    }

    private static func drawCard(in context: CGContext, palette: Palette) {
        let path = CGPath(roundedRect: card, cornerWidth: 120, cornerHeight: 120, transform: nil)

        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 28), blur: 60, color: palette.shadow.cgColor)
        context.addPath(path)
        context.setFillColor(palette.cardFillBottom.cgColor)
        context.fillPath()
        context.restoreGState()

        context.saveGState()
        context.addPath(path)
        context.clip()
        let gradient = CGGradient(
            colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
            colors: [palette.cardFillTop.cgColor, palette.cardFillBottom.cgColor] as CFArray,
            locations: [0, 1]
        )
        if let gradient {
            context.drawLinearGradient(gradient, start: CGPoint(x: card.minX, y: card.minY), end: CGPoint(x: card.maxX, y: card.maxY), options: [])
        }
        context.setFillColor(RGBA(white: 1, alpha: 0.10).cgColor)
        context.fill(CGRect(x: card.minX, y: card.minY, width: card.width, height: 96))
        context.restoreGState()

        context.addPath(path)
        context.setStrokeColor(palette.cardStroke.cgColor)
        context.setLineWidth(4)
        context.strokePath()
    }

    private static func drawTabs(in context: CGContext, palette: Palette) {
        context.setFillColor(palette.arrow.cgColor)
        for x in [372.0, 608.0] {
            let tab = CGRect(x: x, y: 206, width: 44, height: 100)
            context.addPath(CGPath(roundedRect: tab, cornerWidth: 22, cornerHeight: 22, transform: nil))
        }
        context.fillPath()
    }

    private static func drawRenewArrow(in context: CGContext, palette: Palette) {
        let radius: CGFloat = 158
        let lineWidth: CGFloat = 50
        let start = degrees(-48)
        let end = degrees(222)

        context.setStrokeColor(palette.arrow.cgColor)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        context.strokePath()

        let tip = point(onCircleAt: end, radius: radius)
        let tangent = CGPoint(x: -sin(end), y: cos(end))
        let normal = CGPoint(x: cos(end), y: sin(end))
        let headLength: CGFloat = 78
        let headHalfWidth: CGFloat = 62

        context.setFillColor(palette.arrow.cgColor)
        context.move(to: CGPoint(x: tip.x + tangent.x * headLength, y: tip.y + tangent.y * headLength))
        context.addLine(to: CGPoint(x: tip.x + normal.x * headHalfWidth, y: tip.y + normal.y * headHalfWidth))
        context.addLine(to: CGPoint(x: tip.x - normal.x * headHalfWidth, y: tip.y - normal.y * headHalfWidth))
        context.closePath()
        context.fillPath()
    }

    private static func drawCheck(in context: CGContext, palette: Palette) {
        context.setStrokeColor(palette.check.cgColor)
        context.setLineWidth(46)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: CGPoint(x: center.x - 70, y: center.y + 4))
        context.addLine(to: CGPoint(x: center.x - 18, y: center.y + 56))
        context.addLine(to: CGPoint(x: center.x + 78, y: center.y - 52))
        context.strokePath()
    }

    private static func degrees(_ value: CGFloat) -> CGFloat { value * .pi / 180 }

    private static func point(onCircleAt angle: CGFloat, radius: CGFloat) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
}

enum Renderer {
    static func makeContext(size: Int, opaque: Bool) -> CGContext {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: size,
                height: size,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: space,
                bitmapInfo: (opaque ? CGImageAlphaInfo.noneSkipLast : CGImageAlphaInfo.premultipliedLast).rawValue
              ) else {
            fatalError("Could not create bitmap context")
        }
        context.translateBy(x: 0, y: CGFloat(size))
        context.scaleBy(x: 1, y: -1)
        return context
    }

    static func icon(palette: Palette) -> CGImage {
        let context = makeContext(size: 1024, opaque: true)
        let full = CGRect(x: 0, y: 0, width: 1024, height: 1024)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { fatalError("sRGB unavailable") }

        if let colors = palette.background,
           let gradient = CGGradient(colorsSpace: space, colors: colors.map(\.cgColor) as CFArray, locations: [0, 0.55, 1]) {
            context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 1024, y: 1024), options: [])
        }
        let glowColors = [palette.glow.cgColor, RGBA(white: 1, alpha: 0).cgColor] as CFArray
        if let glow = CGGradient(colorsSpace: space, colors: glowColors, locations: [0, 1]) {
            context.drawRadialGradient(glow, startCenter: CGPoint(x: 260, y: 180), startRadius: 0, endCenter: CGPoint(x: 260, y: 180), endRadius: 640, options: [])
        }
        context.clip(to: full)
        Glyph.draw(in: context, palette: palette)
        return image(from: context)
    }

    static func launchLogo(pixelSize: Int) -> CGImage {
        let context = makeContext(size: pixelSize, opaque: false)
        let scale = CGFloat(pixelSize) / max(Glyph.bounds.width, Glyph.bounds.height)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(
            x: -Glyph.bounds.midX + Glyph.bounds.height / 2,
            y: -Glyph.bounds.midY + Glyph.bounds.height / 2
        )
        Glyph.draw(in: context, palette: .launch)
        return image(from: context)
    }

    private static func image(from context: CGContext) -> CGImage {
        guard let image = context.makeImage() else { fatalError("Could not render image") }
        return image
    }

    static func writePNG(_ image: CGImage, to url: URL) {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            fatalError("Could not create \(url.lastPathComponent)")
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { fatalError("Could not write \(url.lastPathComponent)") }
        print("Wrote \(url.path)")
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Renewly/Assets.xcassets")
let iconSet = assets.appendingPathComponent("AppIcon.appiconset")
let logoSet = assets.appendingPathComponent("LaunchLogo.imageset")

guard FileManager.default.fileExists(atPath: iconSet.path) else {
    fatalError("Run from the folder that contains Renewly.xcodeproj")
}
try FileManager.default.createDirectory(at: logoSet, withIntermediateDirectories: true)

Renderer.writePNG(Renderer.icon(palette: .light), to: iconSet.appendingPathComponent("AppIcon.png"))
Renderer.writePNG(Renderer.icon(palette: .dark), to: iconSet.appendingPathComponent("AppIcon-Dark.png"))
Renderer.writePNG(Renderer.icon(palette: .tinted), to: iconSet.appendingPathComponent("AppIcon-Tinted.png"))
for scale in 1...3 {
    let suffix = scale == 1 ? "" : "@\(scale)x"
    Renderer.writePNG(Renderer.launchLogo(pixelSize: 180 * scale), to: logoSet.appendingPathComponent("LaunchLogo\(suffix).png"))
}
