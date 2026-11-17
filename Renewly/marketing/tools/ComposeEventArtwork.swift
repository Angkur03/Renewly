//
// ComposeEventArtwork.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-11-14.
// Copyright © 2026. All rights reserved.
//
// Draws the In-App Event media: the event card (search results, Today and Apps tabs)
// and the event details page header. The App Store lays the event name, description and
// app icon over the lower part, so the artwork has no text and keeps the phones high.
//
// Build: swiftc -parse-as-library -O -D PROMO_VIDEO ComposeEventArtwork.swift ComposeScreenshots.swift ScreenshotCopy.swift -o /tmp/compose-event-artwork
// Run:   /tmp/compose-event-artwork <raw-iphone-dir> <promo-out>
//   <raw-iphone-dir> holds 01_dashboard.png, 02_trial.png and 04_insights.png from capture-screenshots.sh.
//

import AppKit

@main
enum ComposeEventArtwork {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard arguments.count == 2 else { throw ComposeError.usage }
            let raw = URL(fileURLWithPath: arguments[0])
            let out = URL(fileURLWithPath: arguments[1])
            let shots = try PhoneShots(
                center: ComposeScreenshots.loadImage(raw.appendingPathComponent("01_dashboard.png")),
                left: ComposeScreenshots.loadImage(raw.appendingPathComponent("02_trial.png")),
                right: ComposeScreenshots.loadImage(raw.appendingPathComponent("04_insights.png"))
            )
            try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

            let card = try artwork(width: 1920, height: 1080, layout: .card, shots: shots)
            try ComposeScreenshots.writeJPEG(card, to: out.appendingPathComponent("event-card-1920x1080.jpg"))
            let details = try artwork(width: 1080, height: 1920, layout: .details, shots: shots)
            try ComposeScreenshots.writeJPEG(details, to: out.appendingPathComponent("event-details-1080x1920.jpg"))
            print("Saved event artwork to \(out.path)")
        } catch {
            FileHandle.standardError.write(Data("Usage: compose-event-artwork <raw-iphone-dir> <promo-out>\n\(error)\n".utf8))
            exit(1)
        }
    }

    struct PhoneShots {
        let center: NSBitmapImageRep
        let left: NSBitmapImageRep
        let right: NSBitmapImageRep
    }

    /// Sizes are fractions of the canvas width; tops are fractions of the canvas height.
    struct Layout {
        let centerWidth: CGFloat
        let centerTop: CGFloat
        let sideWidth: CGFloat
        let sideTop: CGFloat
        let sideOffset: CGFloat

        static let card = Layout(centerWidth: 0.25, centerTop: 0.07, sideWidth: 0.21, sideTop: 0.2, sideOffset: 0.235)
        static let details = Layout(centerWidth: 0.56, centerTop: 0.12, sideWidth: 0.44, sideTop: 0.2, sideOffset: 0.3)
    }

    static func artwork(width: Int, height: Int, layout: Layout, shots: PhoneShots) throws -> NSBitmapImageRep {
        let canvasWidth = CGFloat(width)
        let canvasHeight = CGFloat(height)
        return try ComposeScreenshots.draw(width: width, height: height) {
            ComposeScreenshots.drawBackground(width: canvasWidth, height: canvasHeight)
            drawGlow(at: NSPoint(x: canvasWidth * 0.5, y: canvasHeight * 0.62), radius: canvasWidth * 0.45)

            let centerX = canvasWidth / 2
            let sideX = canvasWidth * layout.sideOffset
            for (shot, x) in [(shots.left, centerX - sideX), (shots.right, centerX + sideX)] {
                drawPhone(shot, centerX: x, top: canvasHeight * layout.sideTop, screenWidth: canvasWidth * layout.sideWidth,
                          canvasWidth: canvasWidth, canvasHeight: canvasHeight)
            }
            drawPhone(shots.center, centerX: centerX, top: canvasHeight * layout.centerTop, screenWidth: canvasWidth * layout.centerWidth,
                      canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        }
    }

    static func drawPhone(
        _ screenshot: NSBitmapImageRep, centerX: CGFloat, top: CGFloat, screenWidth: CGFloat,
        canvasWidth: CGFloat, canvasHeight: CGFloat
    ) {
        let screenHeight = screenWidth * CGFloat(screenshot.pixelsHigh) / CGFloat(screenshot.pixelsWide)
        let bezel = screenWidth * 0.03
        let frame = NSRect(
            x: centerX - screenWidth / 2 - bezel,
            y: canvasHeight - top - screenHeight - bezel * 2,
            width: screenWidth + bezel * 2,
            height: screenHeight + bezel * 2
        )
        ComposeScreenshots.drawDevice(screenshot, frame: frame, bezel: bezel, cornerRatio: 0.13, canvasWidth: canvasWidth)
    }

    static func drawGlow(at center: NSPoint, radius: CGFloat) {
        let glow = NSGradient(starting: Palette.mint.withAlphaComponent(0.28), ending: Palette.mint.withAlphaComponent(0))
        glow?.draw(fromCenter: center, radius: 0, toCenter: center, radius: radius, options: [])
    }
}
