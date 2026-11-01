//
// ResizeScreenshots.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-25.
// Copyright © 2026. All rights reserved.
//
// Makes iPhone 6.5" (1284 × 2778) and 6.3" (1206 × 2622) copies of the 6.9" screenshots.
// App Store Connect rejects 6.9" files in those slots, and some accounts show them as required.
//
// Build: swiftc -parse-as-library -O ResizeScreenshots.swift -o /tmp/resize-screenshots
// Run:   /tmp/resize-screenshots <screenshots-dir>
//

import AppKit

enum ResizeError: Error, CustomStringConvertible {
    case usage
    case unreadableImage(String)
    case canvasUnavailable
    case encodingFailed(String)

    var description: String {
        switch self {
        case .usage: "Usage: resize-screenshots <screenshots-dir>"
        case .unreadableImage(let path): "Could not read image at \(path)"
        case .canvasUnavailable: "Could not create a drawing canvas"
        case .encodingFailed(let path): "Could not encode \(path)"
        }
    }
}

struct Display {
    let label: String
    let prefix: String
    let width: Int
    let height: Int
}

@main
enum ResizeScreenshots {
    static let sourcePrefix = "iphone-"
    static let displays = [
        Display(label: "6.5\"", prefix: "iphone65-", width: 1284, height: 2778),
        Display(label: "6.3\"", prefix: "iphone63-", width: 1206, height: 2622),
    ]

    static func main() {
        do {
            let arguments = CommandLine.arguments
            guard arguments.count == 2 else { throw ResizeError.usage }
            try run(root: URL(fileURLWithPath: arguments[1]))
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            exit(1)
        }
    }

    static func run(root: URL) throws {
        let files = FileManager.default
        let locales = try files.contentsOfDirectory(atPath: root.path).sorted()
        var written = Array(repeating: 0, count: displays.count)
        for locale in locales {
            let folder = root.appending(path: locale)
            var isDirectory: ObjCBool = false
            guard files.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else { continue }
            for name in try files.contentsOfDirectory(atPath: folder.path).sorted()
            where name.hasPrefix(sourcePrefix) && name.hasSuffix(".jpg") {
                let source = folder.appending(path: name)
                for (index, display) in displays.enumerated() {
                    let target = folder.appending(path: display.prefix + name.dropFirst(sourcePrefix.count))
                    try resize(source, to: target, width: display.width, height: display.height)
                    written[index] += 1
                }
            }
        }
        for (display, count) in zip(displays, written) {
            print("Wrote \(count) iPhone \(display.label) screenshots (\(display.width) × \(display.height))")
        }
    }

    /// Scales to fill the target canvas and trims the few rows left over, since the aspect ratios differ slightly.
    static func resize(_ source: URL, to target: URL, width targetWidth: Int, height targetHeight: Int) throws {
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ResizeError.unreadableImage(source.path)
        }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil, width: targetWidth, height: targetHeight, bitsPerComponent: 8, bytesPerRow: 0,
                  space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              ) else {
            throw ResizeError.canvasUnavailable
        }
        let scale = max(Double(targetWidth) / Double(image.width), Double(targetHeight) / Double(image.height))
        let width = Double(image.width) * scale
        let height = Double(image.height) * scale
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(
            x: (Double(targetWidth) - width) / 2, y: (Double(targetHeight) - height) / 2, width: width, height: height
        ))
        guard let resized = context.makeImage(),
              let data = NSBitmapImageRep(cgImage: resized).representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            throw ResizeError.encodingFailed(target.path)
        }
        try data.write(to: target)
    }
}
