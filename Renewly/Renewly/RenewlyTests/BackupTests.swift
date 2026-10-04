//
// BackupTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import SwiftData
import Testing
@testable import Renewly

@MainActor
@Suite("Backup and restore")
struct BackupTests {
    private let day: TimeInterval = 86_400
    private let receiptBytes = Data("fake-jpeg".utf8)

    private func makeContext() throws -> ModelContext {
        ModelContext(try RenewlyStore.makeContainer(inMemory: true))
    }

    private func seed(_ context: ModelContext, receipts: InMemoryReceiptStore) async throws -> [TrackedItem] {
        let receiptPath = try await receipts.save(receiptBytes)
        let items = [
            TrackedItem(title: "Netflix", category: .subscription, cost: 15.99, currencyCode: "USD",
                        startDate: .now, expirationDate: .now.addingTimeInterval(day * 20),
                        isNotificationEnabled: true, billingCycle: .monthly,
                        cancellationURL: "https://netflix.com/cancel"),
            TrackedItem(title: "MacBook Pro", category: .warranty, cost: 2_499, currencyCode: "EUR",
                        startDate: .now, expirationDate: .now.addingTimeInterval(day * 365),
                        serialNumber: "C02XYZ", retailer: "Apple Store", receiptImagePath: receiptPath)
        ]
        items.forEach(context.insert)
        try context.save()
        return items
    }

    private func backupItem(
        category: String = "warranty",
        cost: Double = 10,
        currency: String = "USD",
        start: Date = .now,
        end: Date = .now.addingTimeInterval(86_400)
    ) -> BackupItem {
        BackupItem(
            id: UUID(), title: "Item", category: category, cost: cost, currencyCode: currency,
            startDate: start, expirationDate: end, isNotificationEnabled: false, serialNumber: nil,
            retailer: nil, billingCycle: "monthly", cancellationURL: nil, createdAt: .now, receiptImage: nil
        )
    }

    @Test func roundTripRestoresEveryFieldAndReceipt() async throws {
        let source = try makeContext()
        let sourceReceipts = InMemoryReceiptStore()
        let originals = try await seed(source, receipts: sourceReceipts)

        let archive = await BackupService(receipts: sourceReceipts).makeArchive(from: originals)
        let decoded = try BackupCoder.decode(try BackupCoder.encode(archive))
        #expect(decoded.items.map(\.id) == archive.items.map(\.id))
        #expect(decoded.items.map(\.receiptImage) == archive.items.map(\.receiptImage))
        for (read, written) in zip(decoded.items, archive.items) {
            // ISO 8601 keeps whole seconds; sub-second precision never affects a renewal day.
            #expect(abs(read.expirationDate.timeIntervalSince(written.expirationDate)) < 1)
            #expect(abs(read.startDate.timeIntervalSince(written.startDate)) < 1)
        }

        let target = try makeContext()
        let targetReceipts = InMemoryReceiptStore()
        let summary = try await BackupService(receipts: targetReceipts).restore(decoded, into: target)

        #expect(summary == RestoreSummary(added: 2))
        let restored = try target.fetch(FetchDescriptor<TrackedItem>(sortBy: [SortDescriptor(\.title)]))
        #expect(restored.map(\.title) == ["MacBook Pro", "Netflix"])

        let laptop = try #require(restored.first)
        #expect(laptop.id == originals[1].id)
        #expect(laptop.cost == 2_499)
        #expect(laptop.currencyCode == "EUR")
        #expect(laptop.serialNumber == "C02XYZ")
        #expect(laptop.retailer == "Apple Store")
        let path = try #require(laptop.receiptImagePath)
        #expect(try await targetReceipts.load(relativePath: path) == receiptBytes)

        let netflix = try #require(restored.last)
        #expect(netflix.isNotificationEnabled)
        #expect(netflix.cancellationURL == "https://netflix.com/cancel")
        #expect(netflix.receiptImagePath == nil)
    }

    @Test func restoringTwiceNeverDuplicates() async throws {
        let context = try makeContext()
        let receipts = InMemoryReceiptStore()
        let items = try await seed(context, receipts: receipts)
        let service = BackupService(receipts: receipts)
        let archive = await service.makeArchive(from: items)

        let summary = try await service.restore(archive, into: context)

        #expect(summary.added == 0)
        #expect(summary.alreadyPresent == 2)
        #expect(try context.fetchCount(FetchDescriptor<TrackedItem>()) == 2)
    }

    @Test func damagedEntriesAreSkipped() async throws {
        let context = try makeContext()
        let archive = BackupArchive(
            formatVersion: 1, exportedAt: .now, appVersion: "1.0",
            items: [
                backupItem(),
                backupItem(category: "lease"),
                backupItem(cost: -5),
                backupItem(cost: .infinity),
                backupItem(currency: "dollars"),
                backupItem(start: .now, end: .now.addingTimeInterval(-86_400))
            ]
        )

        let summary = try await BackupService(receipts: InMemoryReceiptStore()).restore(archive, into: context)

        #expect(summary.added == 1)
        #expect(summary.skippedInvalid == 5)
    }

    @Test func subscriptionsDropWarrantyOnlyFields() throws {
        let backup = BackupItem(
            id: UUID(), title: "  Spotify  ", category: "subscription", cost: 9.99, currencyCode: "USD",
            startDate: .now, expirationDate: .now.addingTimeInterval(86_400), isNotificationEnabled: false,
            serialNumber: "SN123", retailer: "Store", billingCycle: "bogus", cancellationURL: nil,
            createdAt: .now, receiptImage: nil
        )
        let item = try #require(BackupService.validatedItem(from: backup))
        #expect(item.title == "Spotify")
        #expect(item.serialNumber == nil)
        #expect(item.retailer == nil)
        #expect(item.billingCycle == .monthly)
    }

    @Test func rejectsNewerFormatsAndGarbage() throws {
        let newer = BackupArchive(formatVersion: 99, exportedAt: .now, appVersion: "9.0", items: [])
        #expect(throws: BackupError.newerFormat(99)) {
            try BackupCoder.decode(try BackupCoder.encode(newer))
        }
        #expect(throws: BackupError.unreadableFile) {
            try BackupCoder.decode(Data("{\"hello\": 1}".utf8))
        }
    }

    @Test func readsArchiveFromAFile() async throws {
        let archive = BackupArchive(formatVersion: 1, exportedAt: .now, appVersion: "1.0", items: [backupItem()])
        let url = FileManager.default.temporaryDirectory.appending(path: "backup-\(UUID().uuidString).json")
        try BackupCoder.encode(archive).write(to: url)
        defer {
            do { try FileManager.default.removeItem(at: url) } catch { Issue.record("Cleanup failed: \(error)") }
        }

        let read = try await BackupCoder.readArchive(from: url)

        #expect(read.items.map(\.id) == archive.items.map(\.id))
    }

    @Test func viewModelRestoreReportsSummaryAndResyncsReminders() async throws {
        let context = try makeContext()
        let archive = BackupArchive(formatVersion: 1, exportedAt: .now, appVersion: "1.0", items: [backupItem(), backupItem()])
        let url = FileManager.default.temporaryDirectory.appending(path: "backup-\(UUID().uuidString).json")
        try BackupCoder.encode(archive).write(to: url)
        defer {
            do { try FileManager.default.removeItem(at: url) } catch { Issue.record("Cleanup failed: \(error)") }
        }
        let viewModel = BackupViewModel(dependencies: PreviewData.dependencies())

        await viewModel.restore(from: url, into: context)

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.statusMessage == "Restored 2 items.")
        #expect(try context.fetchCount(FetchDescriptor<TrackedItem>()) == 2)
    }

    @Test func viewModelExportPreparesAFile() async throws {
        let context = try makeContext()
        let items = try await seed(context, receipts: InMemoryReceiptStore())
        let viewModel = BackupViewModel(dependencies: PreviewData.dependencies())

        await viewModel.exportBackup(items: items)

        let file = try #require(viewModel.exportFile)
        #expect(viewModel.isExporterPresented)
        #expect(try BackupCoder.decode(file.data).items.count == 2)
        #expect(viewModel.exportFilename.hasPrefix("Renewly Backup "))
    }

    @Test func summaryMessages() {
        #expect(RestoreSummary(added: 1).message == "Restored 1 item.")
        #expect(RestoreSummary(added: 3, alreadyPresent: 2, skippedInvalid: 1, missingReceipts: 1).message
            == "Restored 3 items. 2 were already on this device. 1 damaged entry was skipped. 1 receipt photo could not be restored.")
    }
}
