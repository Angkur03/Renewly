//
// BackupArchive.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// A self-contained backup file: every item plus its receipt photo, so it restores on a new device.
nonisolated struct BackupArchive: Codable, Equatable, Sendable {
    static let currentFormatVersion = 1

    let formatVersion: Int
    let exportedAt: Date
    let appVersion: String
    let items: [BackupItem]
}

nonisolated struct BackupItem: Codable, Equatable, Sendable {
    let id: UUID
    let title: String
    let category: String
    let cost: Double
    let currencyCode: String
    let startDate: Date
    let expirationDate: Date
    let isNotificationEnabled: Bool
    let serialNumber: String?
    let retailer: String?
    let billingCycle: String
    let cancellationURL: String?
    let createdAt: Date
    /// JPEG bytes, base64-encoded in the JSON.
    let receiptImage: Data?
}

nonisolated enum BackupError: Error, Equatable, Sendable {
    case encodingFailed
    case unreadableFile
    case fileTooLarge
    case newerFormat(Int)
    case saveFailed

    var userMessage: String {
        switch self {
        case .encodingFailed: "The backup could not be created. Please try again."
        case .unreadableFile: "That file is not a Renewly backup, or it is damaged."
        case .fileTooLarge: "That file is too large to be a Renewly backup."
        case .newerFormat: "This backup was made by a newer version of Renewly. Update the app, then try again."
        case .saveFailed: "The backup could not be restored. Nothing was changed."
        }
    }
}

nonisolated struct RestoreSummary: Equatable, Sendable {
    var added = 0
    var alreadyPresent = 0
    var skippedInvalid = 0
    var missingReceipts = 0

    var message: String {
        var parts = [added == 1 ? "Restored 1 item." : "Restored \(added) items."]
        if alreadyPresent > 0 {
            parts.append(alreadyPresent == 1
                ? "1 was already on this device."
                : "\(alreadyPresent) were already on this device.")
        }
        if skippedInvalid > 0 {
            parts.append(skippedInvalid == 1
                ? "1 damaged entry was skipped."
                : "\(skippedInvalid) damaged entries were skipped.")
        }
        if missingReceipts > 0 {
            parts.append(missingReceipts == 1
                ? "1 receipt photo could not be restored."
                : "\(missingReceipts) receipt photos could not be restored.")
        }
        return parts.joined(separator: " ")
    }
}

nonisolated enum BackupCoder {
    /// Generous for hundreds of receipt photos, while refusing files that would exhaust memory.
    static let maxFileSize = 500 * 1024 * 1024

    static func encode(_ archive: BackupArchive) throws(BackupError) -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            return try encoder.encode(archive)
        } catch {
            throw .encodingFailed
        }
    }

    static func decode(_ data: Data) throws(BackupError) -> BackupArchive {
        guard data.count <= maxFileSize else { throw .fileTooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive: BackupArchive
        do {
            archive = try decoder.decode(BackupArchive.self, from: data)
        } catch {
            throw .unreadableFile
        }
        guard archive.formatVersion <= BackupArchive.currentFormatVersion else {
            throw .newerFormat(archive.formatVersion)
        }
        return archive
    }

    /// Encodes off the main thread; archives with many receipt photos take a moment.
    @concurrent
    static func encodeInBackground(_ archive: BackupArchive) async throws(BackupError) -> Data {
        try encode(archive)
    }

    /// Reads a file picked in the Files app, which may live outside the sandbox (iCloud Drive, other apps).
    @concurrent
    static func readArchive(from url: URL) async throws(BackupError) -> BackupArchive {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isScoped { url.stopAccessingSecurityScopedResource() }
        }
        let data: Data
        do {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= maxFileSize else { throw BackupError.fileTooLarge }
            data = try Data(contentsOf: url)
        } catch let error as BackupError {
            throw error
        } catch {
            throw .unreadableFile
        }
        return try decode(data)
    }

    static func defaultFilename(for date: Date) -> String {
        "Renewly Backup \(date.formatted(.iso8601.year().month().day()))"
    }
}
