//
// ReceiptPDFExporting.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated struct ReceiptDocument: Sendable, Equatable {
    nonisolated struct Line: Sendable, Equatable {
        let label: String
        let value: String
    }

    let title: String
    let categoryTitle: String
    let headline: String
    let lines: [Line]
    let attachmentTitle: String
    let imageData: Data?
    let generatedAt: Date
}

nonisolated enum PDFExportError: Error, Equatable, Sendable {
    case renderFailed
    case writeFailed

    var userMessage: String {
        switch self {
        case .renderFailed: "The PDF could not be created."
        case .writeFailed: "The PDF could not be saved for sharing."
        }
    }
}

nonisolated protocol ReceiptPDFExporting: Sendable {
    /// Writes the PDF to a temporary file and returns its URL.
    func export(_ document: ReceiptDocument) async throws(PDFExportError) -> URL
}
