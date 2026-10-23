//
// ComposeScreenshots.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//
// Turns raw simulator captures into App Store screenshots, and draws the promotional artwork.
//
// Build: swiftc -parse-as-library -O ComposeScreenshots.swift ScreenshotCopy.swift -o /tmp/compose-screenshots
// Run:   /tmp/compose-screenshots <raw-dir> <screenshots-out> <promo-out> <AppIcon.png>
//

import AppKit

enum ComposeError: Error, CustomStringConvertible {
    case usage
    case unreadableImage(String)
    case canvasUnavailable
    case encodingFailed(String)

    var description: String {
        switch self {
        case .usage: "Usage: compose-screenshots <raw-dir> <screenshots-out> <promo-out> <AppIcon.png>"
        case .unreadableImage(let path): "Could not read image at \(path)"
        case .canvasUnavailable: "Could not create a drawing canvas"
        case .encodingFailed(let path): "Could not encode \(path)"
        }
    }
}

enum Palette {
    static let indigo = NSColor(srgbRed: 0x4F / 255, green: 0x46 / 255, blue: 0xE5 / 255, alpha: 1)
    static let violet = NSColor(srgbRed: 0x6D / 255, green: 0x3B / 255, blue: 0xEA / 255, alpha: 1)
    static let purple = NSColor(srgbRed: 0xA8 / 255, green: 0x55 / 255, blue: 0xF7 / 255, alpha: 1)
    static let mint = NSColor(srgbRed: 0x5E / 255, green: 0xF2 / 255, blue: 0xC4 / 255, alpha: 1)
    static let bezel = NSColor(srgbRed: 0.07, green: 0.07, blue: 0.09, alpha: 1)
}

#if !PROMO_VIDEO
/// The promo video tool compiles this file for its drawing helpers and brings its own entry point.
@main
enum ComposeScreenshotsCommand {
    static func main() {
        ComposeScreenshots.main()
    }
}
#endif

struct ComposeScreenshots {
    /// The iPad paywall is a small form sheet without visible prices, so it makes a weak store image.
    static let skippedShots: Set<String> = ["ipad/07_paywall"]

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            exit(1)
        }
    }

    static func run(arguments: [String]) throws {
        guard arguments.count == 4 else { throw ComposeError.usage }
        let rawRoot = URL(fileURLWithPath: arguments[0])
        let screenshotsRoot = URL(fileURLWithPath: arguments[1])
        let promoRoot = URL(fileURLWithPath: arguments[2])
        let icon = try loadImage(URL(fileURLWithPath: arguments[3]))
        let files = FileManager.default

        for (locale, list) in captions.sorted(by: { $0.key < $1.key }) {
            let localeDir = screenshotsRoot.appending(path: locale)
            try files.createDirectory(at: localeDir, withIntermediateDirectories: true)
            for device in ["iphone", "ipad"] {
                for (index, name) in shotNames.enumerated() where !skippedShots.contains("\(device)/\(name)") {
                    let raw = rawRoot.appending(path: "\(device)/\(locale)/\(name).png")
                    guard files.fileExists(atPath: raw.path) else { continue }
                    let output = localeDir.appending(path: "\(device)-\(name).jpg")
                    let canvas = try composeScreenshot(try loadImage(raw), caption: list[index], isPhone: device == "iphone")
                    try writeJPEG(canvas, to: output)
                    print("\(locale) \(device) \(name)")
                }
            }
        }

        for (alias, source) in screenshotAliases {
            let sourceDir = screenshotsRoot.appending(path: source)
            let aliasDir = screenshotsRoot.appending(path: alias)
            if files.fileExists(atPath: aliasDir.path) {
                try files.removeItem(at: aliasDir)
            }
            try files.copyItem(at: sourceDir, to: aliasDir)
            print("\(alias) uses \(source)")
        }

        try files.createDirectory(at: promoRoot, withIntermediateDirectories: true)
        try writePNG(try subscriptionArtwork(icon: icon), to: promoRoot.appending(path: "subscription-promo-1024.png"))
        let dashboard = rawRoot.appending(path: "iphone/en-US/01_dashboard.png")
        if files.fileExists(atPath: dashboard.path) {
            try writeJPEG(try socialBanner(icon: icon, screenshot: try loadImage(dashboard)), to: promoRoot.appending(path: "social-1200x630.jpg"))
        }
        let paywall = rawRoot.appending(path: "iphone/en-US/07_paywall.png")
        if files.fileExists(atPath: paywall.path) {
            let review = promoRoot.appending(path: "subscription-review-screenshot.png")
            if files.fileExists(atPath: review.path) {
                try files.removeItem(at: review)
            }
            try files.copyItem(at: paywall, to: review)
        }
        print("promo artwork written")
    }

    // MARK: Screenshots

    static func composeScreenshot(_ screenshot: NSBitmapImageRep, caption: Caption, isPhone: Bool) throws -> NSBitmapImageRep {
        let width = CGFloat(screenshot.pixelsWide)
        let height = CGFloat(screenshot.pixelsHigh)
        return try draw(width: screenshot.pixelsWide, height: screenshot.pixelsHigh) {
            drawBackground(width: width, height: height)

            let margin = width * 0.07
            let headlineSize = width * (isPhone ? 0.083 : 0.06)
            var top = height * (isPhone ? 0.05 : 0.04)
            top += drawText(
                styled(caption.headline, size: headlineSize, weight: .heavy, color: .white),
                top: top, width: width, height: height, margin: margin, maxHeight: headlineSize * 3.6
            )
            top += headlineSize * 0.3
            top += drawText(
                styled(caption.subheadline, size: headlineSize * 0.44, weight: .medium, color: NSColor.white.withAlphaComponent(0.85)),
                top: top, width: width, height: height, margin: margin, maxHeight: headlineSize * 1.3
            )

            let screenWidth = width * (isPhone ? 0.76 : 0.78)
            let screenHeight = height * screenWidth / width
            let bezel = screenWidth * (isPhone ? 0.03 : 0.02)
            let frame = NSRect(
                x: (width - screenWidth) / 2 - bezel,
                y: height - (top + height * 0.035) - screenHeight - bezel * 2,
                width: screenWidth + bezel * 2,
                height: screenHeight + bezel * 2
            )
            drawDevice(screenshot, frame: frame, bezel: bezel, cornerRatio: isPhone ? 0.13 : 0.045, canvasWidth: width)
        }
    }

    static func drawBackground(width: CGFloat, height: CGFloat) {
        let full = NSRect(x: 0, y: 0, width: width, height: height)
        NSGradient(colors: [Palette.indigo, Palette.violet, Palette.purple], atLocations: [0, 0.55, 1], colorSpace: .sRGB)?
            .draw(in: full, angle: -65)
        let glow = NSGradient(starting: NSColor.white.withAlphaComponent(0.22), ending: NSColor.white.withAlphaComponent(0))
        let center = NSPoint(x: width * 0.18, y: height * 0.9)
        glow?.draw(fromCenter: center, radius: 0, toCenter: center, radius: width * 0.75, options: [])
    }

    static func drawDevice(_ screenshot: NSBitmapImageRep, frame: NSRect, bezel: CGFloat, cornerRatio: CGFloat, canvasWidth: CGFloat) {
        let corner = frame.width * cornerRatio
        let body = NSBezierPath(roundedRect: frame, xRadius: corner, yRadius: corner)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowBlurRadius = canvasWidth * 0.045
        shadow.shadowOffset = NSSize(width: 0, height: -canvasWidth * 0.015)
        shadow.set()
        Palette.bezel.setFill()
        body.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.withAlphaComponent(0.28).setStroke()
        body.lineWidth = canvasWidth * 0.003
        body.stroke()

        let screen = frame.insetBy(dx: bezel, dy: bezel)
        let screenCorner = max(corner - bezel, 0)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: screen, xRadius: screenCorner, yRadius: screenCorner).addClip()
        screenshot.draw(in: screen)
        NSGraphicsContext.restoreGraphicsState()
    }

    // MARK: Promo artwork

    /// Artwork for the promoted in-app purchase. Apple asks for no text here, so it is the icon with a crown.
    static func subscriptionArtwork(icon: NSBitmapImageRep) throws -> NSBitmapImageRep {
        let size: CGFloat = 1024
        return try draw(width: 1024, height: 1024) {
            drawBackground(width: size, height: size)
            let iconSize = size * 0.56
            let iconRect = NSRect(x: (size - iconSize) / 2, y: (size - iconSize) / 2 - size * 0.04, width: iconSize, height: iconSize)
            drawIcon(icon, in: iconRect, canvasWidth: size)

            let crownSize = size * 0.2
            if let crown = NSImage(systemSymbolName: "crown.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(.init(pointSize: crownSize, weight: .bold).applying(.init(paletteColors: [NSColor.systemYellow]))) {
                let crownRect = NSRect(x: (size - crownSize * 1.25) / 2, y: iconRect.maxY - crownSize * 0.35, width: crownSize * 1.25, height: crownSize)
                NSGraphicsContext.saveGraphicsState()
                let shadow = NSShadow()
                shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
                shadow.shadowBlurRadius = 18
                shadow.shadowOffset = NSSize(width: 0, height: -6)
                shadow.set()
                crown.draw(in: crownRect)
                NSGraphicsContext.restoreGraphicsState()
            }
        }
    }

    /// 1200×630 banner for the website, social posts and press.
    static func socialBanner(icon: NSBitmapImageRep, screenshot: NSBitmapImageRep) throws -> NSBitmapImageRep {
        let width: CGFloat = 1200
        let height: CGFloat = 630
        return try draw(width: 1200, height: 630) {
            drawBackground(width: width, height: height)

            let iconSize: CGFloat = 120
            drawIcon(icon, in: NSRect(x: 80, y: height - 80 - iconSize, width: iconSize, height: iconSize), canvasWidth: width)
            var top: CGFloat = 80 + iconSize + 36
            let textWidth: CGFloat = 640
            top += drawText(styled("Renewly", size: 64, weight: .heavy, color: .white), top: top, width: width, height: height, left: 80, textWidth: textWidth, maxHeight: 80, alignment: .left)
            top += 8
            top += drawText(styled("Never pay for a **forgotten trial**", size: 40, weight: .bold, color: .white), top: top, width: width, height: height, left: 80, textWidth: textWidth, maxHeight: 110, alignment: .left)
            top += 14
            _ = drawText(styled("Subscriptions, free trials and warranties.\nPrivate, on your iPhone.", size: 26, weight: .medium, color: NSColor.white.withAlphaComponent(0.85)), top: top, width: width, height: height, left: 80, textWidth: textWidth, maxHeight: 80, alignment: .left)

            let screenWidth: CGFloat = 330
            let screenHeight = screenWidth * CGFloat(screenshot.pixelsHigh) / CGFloat(screenshot.pixelsWide)
            let bezel = screenWidth * 0.03
            let frame = NSRect(x: width - 80 - screenWidth - bezel * 2, y: height - 60 - screenHeight - bezel * 2, width: screenWidth + bezel * 2, height: screenHeight + bezel * 2)
            drawDevice(screenshot, frame: frame, bezel: bezel, cornerRatio: 0.13, canvasWidth: width)
        }
    }

    static func drawIcon(_ icon: NSBitmapImageRep, in rect: NSRect, canvasWidth: CGFloat) {
        let corner = rect.width * 0.225
        let path = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowBlurRadius = canvasWidth * 0.03
        shadow.shadowOffset = NSSize(width: 0, height: -canvasWidth * 0.01)
        shadow.set()
        NSColor.white.setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()
        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        icon.draw(in: rect)
        NSGraphicsContext.restoreGraphicsState()
    }

    // MARK: Text

    static func font(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        let system = NSFont.systemFont(ofSize: size, weight: weight)
        guard let rounded = system.fontDescriptor.withDesign(.rounded), let font = NSFont(descriptor: rounded, size: size) else {
            return system
        }
        return font
    }

    /// Builds the text with `**highlighted**` parts in mint.
    static func styled(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let baseFont = font(size: size, weight: weight)
        for (index, part) in text.components(separatedBy: "**").enumerated() where !part.isEmpty {
            result.append(NSAttributedString(string: part, attributes: [
                .font: baseFont,
                .foregroundColor: index.isMultiple(of: 2) ? color : Palette.mint,
            ]))
        }
        return result
    }

    /// Draws text below `top` (measured from the canvas top), shrinking it until it fits `maxHeight`. Returns the height used.
    @discardableResult
    static func drawText(
        _ text: NSAttributedString, top: CGFloat, width: CGFloat, height: CGFloat,
        margin: CGFloat, maxHeight: CGFloat
    ) -> CGFloat {
        drawText(text, top: top, width: width, height: height, left: margin, textWidth: width - margin * 2, maxHeight: maxHeight, alignment: .center)
    }

    static func drawText(
        _ text: NSAttributedString, top: CGFloat, width: CGFloat, height: CGFloat,
        left: CGFloat, textWidth: CGFloat, maxHeight: CGFloat, alignment: NSTextAlignment
    ) -> CGFloat {
        var scale: CGFloat = 1
        var fitted = text
        var bounds = measure(fitted, width: textWidth, alignment: alignment)
        while bounds.height > maxHeight, scale > 0.5 {
            scale -= 0.04
            fitted = scaled(text, by: scale)
            bounds = measure(fitted, width: textWidth, alignment: alignment)
        }
        let rect = NSRect(x: left, y: height - top - bounds.height, width: textWidth, height: bounds.height)
        withParagraph(fitted, alignment: alignment).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        return bounds.height
    }

    static func measure(_ text: NSAttributedString, width: CGFloat, alignment: NSTextAlignment) -> CGSize {
        withParagraph(text, alignment: alignment)
            .boundingRect(with: NSSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading])
            .integral.size
    }

    static func withParagraph(_ text: NSAttributedString, alignment: NSTextAlignment) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineHeightMultiple = 1.05
        paragraph.lineBreakStrategy = .standard
        let result = NSMutableAttributedString(attributedString: text)
        result.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: result.length))
        return result
    }

    static func scaled(_ text: NSAttributedString, by scale: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: text)
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            guard let current = value as? NSFont,
                  let resized = NSFont(descriptor: current.fontDescriptor, size: current.pointSize * scale) else { return }
            result.addAttribute(.font, value: resized, range: range)
        }
        return result
    }

    // MARK: Canvas and files

    static func draw(width: Int, height: Int, _ body: () -> Void) throws -> NSBitmapImageRep {
        guard let canvas = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: canvas) else {
            throw ComposeError.canvasUnavailable
        }
        canvas.size = NSSize(width: width, height: height)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        body()
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()
        return canvas
    }

    static func loadImage(_ url: URL) throws -> NSBitmapImageRep {
        guard let data = FileManager.default.contents(atPath: url.path), let image = NSBitmapImageRep(data: data) else {
            throw ComposeError.unreadableImage(url.path)
        }
        image.size = NSSize(width: image.pixelsWide, height: image.pixelsHigh)
        return image
    }

    static func writeJPEG(_ image: NSBitmapImageRep, to url: URL) throws {
        guard let data = image.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            throw ComposeError.encodingFailed(url.path)
        }
        try data.write(to: url)
    }

    static func writePNG(_ image: NSBitmapImageRep, to url: URL) throws {
        guard let data = image.representation(using: .png, properties: [:]) else {
            throw ComposeError.encodingFailed(url.path)
        }
        try data.write(to: url)
    }
}
