//
// ReceiptImageStore.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import UIKit

actor ReceiptImageStore: ReceiptImageStoring {
    static let directoryName = "Receipts"

    private let rootDirectory: URL
    private let compressionQuality: CGFloat

    init(rootDirectory: URL = .applicationSupportDirectory, compressionQuality: CGFloat = 0.8) {
        self.rootDirectory = rootDirectory
        self.compressionQuality = compressionQuality
    }

    func save(_ imageData: Data) throws(ReceiptStorageError) -> String {
        guard let image = UIImage(data: imageData),
              let jpegData = image.jpegData(compressionQuality: compressionQuality) else {
            throw .invalidImageData
        }

        let relativePath = "\(Self.directoryName)/\(UUID().uuidString).jpg"
        do {
            try prepareDirectory()
            try jpegData.write(
                to: rootDirectory.appending(path: relativePath),
                options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
            )
        } catch {
            throw .writeFailed
        }
        return relativePath
    }

    func load(relativePath: String) throws(ReceiptStorageError) -> Data {
        let url = try resolvedURL(for: relativePath)
        do {
            return try Data(contentsOf: url)
        } catch {
            throw .readFailed
        }
    }

    func delete(relativePath: String) throws(ReceiptStorageError) {
        let url = try resolvedURL(for: relativePath)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw .deleteFailed
        }
    }

    private func prepareDirectory() throws {
        var directory = rootDirectory.appending(path: Self.directoryName, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
    }

    private func resolvedURL(for relativePath: String) throws(ReceiptStorageError) -> URL {
        let components = relativePath.split(separator: "/")
        guard !relativePath.hasPrefix("/"),
              !components.isEmpty,
              !components.contains(where: { $0 == ".." || $0 == "." }) else {
            throw .invalidPath
        }
        return rootDirectory.appending(path: relativePath)
    }
}
