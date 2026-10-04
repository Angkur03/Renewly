//
// ReminderSyncService.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import OSLog
import SwiftData

nonisolated struct ReminderSyncResult: Equatable, Sendable {
    var rescheduled = 0
    var disabledOverQuota = 0
    var failed = 0
}

/// Rebuilds pending reminders from SwiftData so the system queue always matches the stored items,
/// e.g. after the reminder schedule changes or a Pro subscription lapses.
@MainActor
struct ReminderSyncService {
    private let notifications: any NotificationScheduling
    private let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly", category: "ReminderSync")

    init(notifications: any NotificationScheduling) {
        self.notifications = notifications
    }

    @discardableResult
    func resync(isPro: Bool, in context: ModelContext) async -> ReminderSyncResult {
        var result = ReminderSyncResult()
        let descriptor = FetchDescriptor<TrackedItem>(
            predicate: #Predicate { $0.isNotificationEnabled },
            sortBy: [SortDescriptor(\.expirationDate)]
        )
        let items: [TrackedItem]
        do {
            items = try context.fetch(descriptor)
        } catch {
            logger.error("Reminder sync fetch failed: \(error.localizedDescription, privacy: .public)")
            return result
        }

        let allowedCount = isPro ? items.count : min(items.count, NotificationManager.freeAlertLimit)
        let kept = Array(items.prefix(allowedCount))
        let overQuota = items.dropFirst(allowedCount)

        for item in overQuota {
            await notifications.cancel(for: item.id)
            item.isNotificationEnabled = false
            result.disabledOverQuota += 1
        }

        let keptIDs = Set(kept.map(\.id))
        for item in kept {
            guard !Task.isCancelled else { break }
            do {
                try await notifications.schedule(for: item.snapshot, activeAlertItemIDs: keptIDs, isPro: isPro)
                result.rescheduled += 1
            } catch {
                result.failed += 1
                logger.error("Reminder sync failed for an item: \(error.userMessage, privacy: .public)")
            }
        }

        if result.disabledOverQuota > 0 {
            do {
                try context.save()
            } catch {
                context.rollback()
                logger.error("Reminder sync could not persist quota changes.")
            }
        }
        return result
    }
}
