//
// ReceiptImageStoreTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
import UIKit
@testable import Renewly

@Suite("ReceiptImageStore")
struct ReceiptImageStoreTests {
    private let rootDirectory: URL
    private let store: ReceiptImageStore

    init() {
        rootDirectory = FileManager.default.temporaryDirectory
            .appending(path: "ReceiptImageStoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        store = ReceiptImageStore(rootDirectory: rootDirectory)
    }

    @MainActor
    private func samplePNGData() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        return try #require(image.pngData())
    }

    @Test("Saving returns a relative path inside the Receipts folder and writes a JPEG")
    func saveWritesRelativeJPEG() async throws {
        let path = try await store.save(try await samplePNGData())

        #expect(path.hasPrefix("Receipts/"))
        #expect(path.hasSuffix(".jpg"))
        #expect(!path.hasPrefix("/"))

        let fileURL = rootDirectory.appending(path: path)
        #expect(FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)))

        let values = try rootDirectory.appending(path: "Receipts", directoryHint: .isDirectory)
            .resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
    }

    @Test("Load returns the saved bytes")
    func loadRoundTrips() async throws {
        let path = try await store.save(try await samplePNGData())
        let loaded = try await store.load(relativePath: path)
        #expect(UIImage(data: loaded) != nil)
    }

    @Test("Delete removes the file and is idempotent")
    func deleteRemovesFile() async throws {
        let path = try await store.save(try await samplePNGData())
        try await store.delete(relativePath: path)
        try await store.delete(relativePath: path)

        await #expect(throws: ReceiptStorageError.readFailed) {
            _ = try await store.load(relativePath: path)
        }
    }

    @Test("Invalid image data is rejected")
    func rejectsInvalidImageData() async {
        await #expect(throws: ReceiptStorageError.invalidImageData) {
            _ = try await store.save(Data("not an image".utf8))
        }
    }

    @Test("Paths that escape the store directory are rejected", arguments: [
        "../secrets.jpg", "/etc/passwd", "Receipts/../../x.jpg", ""
    ])
    func rejectsTraversal(path: String) async {
        await #expect(throws: ReceiptStorageError.invalidPath) {
            _ = try await store.load(relativePath: path)
        }
    }
}
