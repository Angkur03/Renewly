//
// BackupService.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import OSLog
import SwiftData

/// Builds backup archives from the store and restores them into it. Restores only add: items that already exist
/// (same ID) are left alone, so restoring the same file twice is harmless.
struct BackupService {
    private let receipts: any ReceiptImageStoring
    private let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly", category: "Backup")

    init(receipts: any ReceiptImageStoring) {
        self.receipts = receipts
    }

    func makeArchive(from items: [TrackedItem], now: Date = .now, appVersion: String = Self.appVersion) async -> BackupArchive {
        var backupItems: [BackupItem] = []
        for item in items.sorted(by: { $0.createdAt < $1.createdAt }) {
            backupItems.append(BackupItem(
                id: item.id,
                title: item.title,
                category: item.category.rawValue,
                cost: item.cost,
                currencyCode: item.currencyCode,
                startDate: item.startDate,
                expirationDate: item.expirationDate,
                isNotificationEnabled: item.isNotificationEnabled,
                serialNumber: item.serialNumber,
                retailer: item.retailer,
                billingCycle: item.billingCycle.rawValue,
                cancellationURL: item.cancellationURL,
                createdAt: item.createdAt,
                receiptImage: await receiptData(at: item.receiptImagePath),
                trialEndDate: item.trialEndDate
            ))
        }
        return BackupArchive(
            formatVersion: BackupArchive.currentFormatVersion,
            exportedAt: now,
            appVersion: appVersion,
            items: backupItems
        )
    }

    func restore(_ archive: BackupArchive, into context: ModelContext) async throws(BackupError) -> RestoreSummary {
        var summary = RestoreSummary()
        let existingIDs: Set<UUID>
        do {
            existingIDs = Set(try context.fetch(FetchDescriptor<TrackedItem>()).map(\.id))
        } catch {
            throw .saveFailed
        }

        var savedReceiptPaths: [String] = []
        var seenIDs = existingIDs
        for backupItem in archive.items {
            guard !seenIDs.contains(backupItem.id) else {
                summary.alreadyPresent += 1
                continue
            }
            guard let item = Self.validatedItem(from: backupItem) else {
                summary.skippedInvalid += 1
                continue
            }
            seenIDs.insert(backupItem.id)
            if let image = backupItem.receiptImage {
                do {
                    let path = try await receipts.save(image)
                    item.receiptImagePath = path
                    savedReceiptPaths.append(path)
                } catch {
                    summary.missingReceipts += 1
                }
            }
            context.insert(item)
            summary.added += 1
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            for path in savedReceiptPaths {
                await deleteReceiptQuietly(at: path)
            }
            throw .saveFailed
        }
        return summary
    }

    /// Backup files can be edited by hand or damaged; never trust their values.
    static func validatedItem(from backup: BackupItem) -> TrackedItem? {
        guard let category = ItemCategory(rawValue: backup.category),
              let title = ItemEditorViewModel.sanitized(backup.title, maxLength: ItemEditorViewModel.maxTitleLength),
              backup.cost.isFinite, backup.cost >= 0, backup.cost <= ItemEditorViewModel.maxCost,
              backup.currencyCode.count == 3, backup.currencyCode.allSatisfy({ $0.isASCII && $0.isUppercase }),
              backup.expirationDate >= backup.startDate else {
            return nil
        }
        let isSubscription = category == .subscription
        let cancellationURL = isSubscription
            ? backup.cancellationURL.flatMap { ItemEditorViewModel.sanitized($0, maxLength: 2048) }
            : nil
        return TrackedItem(
            id: backup.id,
            title: title,
            category: category,
            cost: backup.cost,
            currencyCode: backup.currencyCode,
            startDate: backup.startDate,
            expirationDate: backup.expirationDate,
            isNotificationEnabled: backup.isNotificationEnabled,
            serialNumber: isSubscription ? nil : backup.serialNumber.flatMap {
                ItemEditorViewModel.sanitized($0, maxLength: ItemEditorViewModel.maxFieldLength)
            },
            retailer: isSubscription ? nil : backup.retailer.flatMap {
                ItemEditorViewModel.sanitized($0, maxLength: ItemEditorViewModel.maxFieldLength)
            },
            billingCycle: BillingCycle(rawValue: backup.billingCycle) ?? .monthly,
            cancellationURL: cancellationURL,
            createdAt: backup.createdAt,
            trialEndDate: isSubscription ? backup.trialEndDate : nil
        )
    }

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    private func receiptData(at path: String?) async -> Data? {
        guard let path else { return nil }
        do {
            return try await receipts.load(relativePath: path)
        } catch {
            logger.error("Receipt left out of backup: \(error.userMessage, privacy: .public)")
            return nil
        }
    }

    private func deleteReceiptQuietly(at path: String) async {
        do {
            try await receipts.delete(relativePath: path)
        } catch {
            logger.error("Receipt cleanup after failed restore: \(error.userMessage, privacy: .public)")
        }
    }
}
