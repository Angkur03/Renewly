//
// ReceiptTextRecognizing.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import ImageIO
import Vision

nonisolated enum ReceiptScanError: Error, Equatable, Sendable {
    case unreadableImage
    case recognitionFailed
    case cancelled

    var userMessage: String {
        switch self {
        case .unreadableImage: "That photo could not be read. Try a clearer picture."
        case .recognitionFailed: "Text on the receipt could not be recognised. You can still fill in the details yourself."
        case .cancelled: "Scanning was cancelled."
        }
    }
}

/// Reads the text lines on a receipt or warranty card, top to bottom.
nonisolated protocol ReceiptTextRecognizing: Sendable {
    func recognizeLines(in imageData: Data) async throws(ReceiptScanError) -> [String]
}

/// On-device OCR with Vision. Nothing leaves the phone.
nonisolated struct VisionReceiptTextRecognizer: ReceiptTextRecognizing {
    /// Vision is slow and memory hungry on full-resolution camera photos; this is plenty for receipt text.
    static let maxPixelSize = 3_000

    @concurrent
    func recognizeLines(in imageData: Data) async throws(ReceiptScanError) -> [String] {
        guard let (image, orientation) = Self.decode(imageData) else { throw .unreadableImage }
        guard !Task.isCancelled else { throw .cancelled }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
        do {
            try handler.perform([request])
        } catch {
            throw Task.isCancelled ? .cancelled : .recognitionFailed
        }
        guard !Task.isCancelled else { throw .cancelled }

        let observations = request.results ?? []
        return Self.orderedLines(from: observations)
    }

    /// Vision returns observations in no guaranteed order; sort into reading order (top to bottom, then left to right)
    /// and merge fragments that sit on the same printed line, such as "TOTAL" and "$24.99".
    static func orderedLines(from observations: [VNRecognizedTextObservation]) -> [String] {
        let fragments = observations.compactMap { observation -> (box: CGRect, text: String)? in
            guard let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespaces),
                  !text.isEmpty else { return nil }
            return (observation.boundingBox, text)
        }
        // Vision's coordinates start bottom-left, so a larger midY is higher on the page.
        let sorted = fragments.sorted { $0.box.midY > $1.box.midY }

        var rows: [[(box: CGRect, text: String)]] = []
        for fragment in sorted {
            if let last = rows.last?.first, abs(last.box.midY - fragment.box.midY) < max(last.box.height, fragment.box.height) * 0.5 {
                rows[rows.count - 1].append(fragment)
            } else {
                rows.append([fragment])
            }
        }
        return rows.map { row in
            row.sorted { $0.box.minX < $1.box.minX }.map(\.text).joined(separator: " ")
        }
    }

    private static func decode(_ data: Data) -> (CGImage, CGImagePropertyOrientation)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            // Bakes the EXIF rotation into the pixels, so Vision always sees an upright image.
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return (image, .up)
    }
}
