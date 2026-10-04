//
// ReceiptImageStoring.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum ReceiptStorageError: Error, Equatable, Sendable {
    case invalidImageData
    case invalidPath
    case writeFailed
    case readFailed
    case deleteFailed

    var userMessage: String {
        switch self {
        case .invalidImageData: "The selected image could not be read."
        case .invalidPath: "The receipt location is invalid."
        case .writeFailed: "The receipt image could not be saved."
        case .readFailed: "The saved receipt image could not be loaded."
        case .deleteFailed: "The old receipt image could not be removed."
        }
    }
}

nonisolated protocol ReceiptImageStoring: Sendable {
    /// Returns the path relative to the store's root directory.
    func save(_ imageData: Data) async throws(ReceiptStorageError) -> String
    func load(relativePath: String) async throws(ReceiptStorageError) -> Data
    func delete(relativePath: String) async throws(ReceiptStorageError)
}
