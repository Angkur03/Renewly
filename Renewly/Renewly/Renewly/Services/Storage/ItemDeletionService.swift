//
// ItemDeletionService.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import OSLog
import SwiftData

/// Removes an item together with its pending reminders and receipt image.
@MainActor
struct ItemDeletionService {
    private let notifications: any NotificationScheduling
    private let receipts: any ReceiptImageStoring
    private let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly", category: "ItemDeletion")

    init(dependencies: AppDependencies) {
        notifications = dependencies.notifications
        receipts = dependencies.receipts
    }

    /// Returns `false` when the store could not be saved; the item is then left untouched.
    func delete(_ item: TrackedItem, in context: ModelContext) async -> Bool {
        let itemID = item.id
        let receiptPath = item.receiptImagePath

        context.delete(item)
        do {
            try context.save()
        } catch {
            context.rollback()
            return false
        }

        await notifications.cancel(for: itemID)
        guard let receiptPath else { return true }
        do {
            try await receipts.delete(relativePath: receiptPath)
        } catch {
            logger.error("Orphaned receipt image could not be removed: \(error.userMessage, privacy: .public)")
        }
        return true
    }
}
