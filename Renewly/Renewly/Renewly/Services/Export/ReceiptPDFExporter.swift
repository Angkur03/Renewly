//
// ReceiptPDFExporter.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import UIKit

actor ReceiptPDFExporter: ReceiptPDFExporting {
    static let pageSize = CGSize(width: 612, height: 792)
    static let margin: CGFloat = 48
    static let minimumImageHeight: CGFloat = 220

    /// Fixed print palette; dynamic system colors would render white text in Dark Mode.
    private enum Ink {
        static let primary = UIColor(white: 0.08, alpha: 1)
        static let secondary = UIColor(white: 0.42, alpha: 1)
        static let tertiary = UIColor(white: 0.6, alpha: 1)
        static let stripe = UIColor(white: 0.96, alpha: 1)
        static let rule = UIColor(white: 0.85, alpha: 1)
        static let accent = UIColor(red: 0.35, green: 0.34, blue: 0.84, alpha: 1)
    }

    private let outputDirectory: URL

    init(outputDirectory: URL = FileManager.default.temporaryDirectory.appending(path: "Exports", directoryHint: .isDirectory)) {
        self.outputDirectory = outputDirectory
    }

    func export(_ document: ReceiptDocument) throws(PDFExportError) -> URL {
        let data = render(document)
        guard !data.isEmpty else { throw .renderFailed }

        let url = outputDirectory.appending(path: Self.fileName(for: document))
        do {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            throw .writeFailed
        }
        return url
    }

    func render(_ document: ReceiptDocument) -> Data {
        let bounds = CGRect(origin: .zero, size: Self.pageSize)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: document.title,
            kCGPDFContextCreator as String: "Renewly"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        let image = document.imageData.flatMap(UIImage.init(data:))

        return renderer.pdfData { context in
            var page = 1
            context.beginPage()
            var cursor = drawHeader(document, in: bounds)
            cursor = drawLines(document.lines, from: cursor, in: bounds)

            if let image {
                let footerTop = bounds.maxY - Self.margin - 20
                if footerTop - cursor < Self.minimumImageHeight {
                    drawFooter(document, page: page, in: bounds)
                    context.beginPage()
                    page += 1
                    cursor = Self.margin
                }
                cursor = drawSectionTitle(document.attachmentTitle, at: cursor, in: bounds)
                let available = CGRect(
                    x: Self.margin,
                    y: cursor,
                    width: bounds.width - Self.margin * 2,
                    height: footerTop - cursor - 12
                )
                drawImage(image, fittedIn: available)
            } else {
                cursor = drawSectionTitle(document.attachmentTitle, at: cursor + 8, in: bounds)
                draw("No image attached.", font: .systemFont(ofSize: 12), color: Ink.secondary,
                     in: CGRect(x: Self.margin, y: cursor, width: bounds.width - Self.margin * 2, height: 20))
            }
            drawFooter(document, page: page, in: bounds)
        }
    }

    // MARK: Drawing

    private func drawHeader(_ document: ReceiptDocument, in bounds: CGRect) -> CGFloat {
        let width = bounds.width - Self.margin * 2
        var y = Self.margin

        let band = CGRect(x: 0, y: 0, width: bounds.width, height: 6)
        Ink.accent.setFill()
        UIRectFill(band)

        y += draw("RENEWLY", font: .systemFont(ofSize: 11, weight: .heavy), color: Ink.accent, kern: 2,
                  in: CGRect(x: Self.margin, y: y, width: width, height: 16))
        y += 6
        y += draw(document.title, font: .systemFont(ofSize: 26, weight: .bold), color: Ink.primary,
                  in: CGRect(x: Self.margin, y: y, width: width, height: 80))
        y += 4
        y += draw("\(document.categoryTitle)  ·  \(document.headline)", font: .systemFont(ofSize: 14, weight: .medium),
                  color: Ink.secondary, in: CGRect(x: Self.margin, y: y, width: width, height: 40))
        y += 16

        Ink.rule.setFill()
        UIRectFill(CGRect(x: Self.margin, y: y, width: width, height: 0.5))
        return y + 16
    }

    private func drawLines(_ lines: [ReceiptDocument.Line], from top: CGFloat, in bounds: CGRect) -> CGFloat {
        let labelWidth: CGFloat = 150
        let valueX = Self.margin + labelWidth
        let valueWidth = bounds.width - Self.margin - valueX
        var y = top

        for (index, line) in lines.enumerated() {
            let valueHeight = height(of: line.value, font: .systemFont(ofSize: 13, weight: .semibold), width: valueWidth)
            let rowHeight = max(valueHeight, 16) + 12
            if index.isMultiple(of: 2) {
                Ink.stripe.setFill()
                UIBezierPath(roundedRect: CGRect(x: Self.margin - 8, y: y - 4, width: bounds.width - Self.margin * 2 + 16, height: rowHeight),
                             cornerRadius: 6).fill()
            }
            draw(line.label, font: .systemFont(ofSize: 12), color: Ink.secondary,
                 in: CGRect(x: Self.margin, y: y + 2, width: labelWidth - 8, height: rowHeight))
            draw(line.value, font: .systemFont(ofSize: 13, weight: .semibold), color: Ink.primary,
                 in: CGRect(x: valueX, y: y, width: valueWidth, height: valueHeight + 4))
            y += rowHeight
        }
        return y + 16
    }

    private func drawSectionTitle(_ title: String, at top: CGFloat, in bounds: CGRect) -> CGFloat {
        top + draw(title, font: .systemFont(ofSize: 15, weight: .bold), color: Ink.primary,
                   in: CGRect(x: Self.margin, y: top, width: bounds.width - Self.margin * 2, height: 24)) + 10
    }

    private func drawImage(_ image: UIImage, fittedIn rect: CGRect) {
        guard rect.height > 0, image.size.width > 0, image.size.height > 0 else { return }
        let scale = min(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let frame = CGRect(x: rect.midX - size.width / 2, y: rect.minY, width: size.width, height: size.height)

        let path = UIBezierPath(roundedRect: frame, cornerRadius: 8)
        UIGraphicsGetCurrentContext()?.saveGState()
        path.addClip()
        image.draw(in: frame)
        UIGraphicsGetCurrentContext()?.restoreGState()
        Ink.rule.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private func drawFooter(_ document: ReceiptDocument, page: Int, in bounds: CGRect) {
        let generated = document.generatedAt.formatted(date: .abbreviated, time: .shortened)
        draw("Generated by Renewly on \(generated)  ·  Stored only on this device  ·  Page \(page)",
             font: .systemFont(ofSize: 9), color: Ink.tertiary,
             in: CGRect(x: Self.margin, y: bounds.maxY - Self.margin, width: bounds.width - Self.margin * 2, height: 14))
    }

    @discardableResult
    private func draw(_ text: String, font: UIFont, color: UIColor, kern: CGFloat = 0, in rect: CGRect) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .kern: kern]
        let string = NSAttributedString(string: text, attributes: attributes)
        let measured = string.boundingRect(
            with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let height = min(ceil(measured.height), rect.height)
        string.draw(with: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: height),
                    options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine], context: nil)
        return height
    }

    private func height(of text: String, font: UIFont, width: CGFloat) -> CGFloat {
        ceil(NSAttributedString(string: text, attributes: [.font: font])
            .boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                          options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
    }

    static func fileName(for document: ReceiptDocument) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -_"))
        let cleaned = String(document.title.unicodeScalars.filter(allowed.contains))
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "-")
        let base = cleaned.isEmpty ? "Receipt" : String(cleaned.prefix(60))
        let day = document.generatedAt.formatted(.iso8601.year().month().day())
        return "Renewly-\(base)-\(day).pdf"
    }
}
