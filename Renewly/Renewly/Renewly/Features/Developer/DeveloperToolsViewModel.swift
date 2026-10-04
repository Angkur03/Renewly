//
// DeveloperToolsViewModel.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

#if DEBUG
import Foundation
import Observation
import OSLog
import SwiftData

@Observable
@MainActor
final class DeveloperToolsViewModel {
    static let testAlertDelaySeconds = 5

    var statusMessage: String?
    var errorMessage: String?
    var isDeleteConfirmationPresented = false
    private(set) var isWorking = false
    private(set) var actionCount = 0
    private(set) var pendingAlertCount = 0

    @ObservationIgnored private let dependencies: AppDependencies
    @ObservationIgnored private let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly", category: "DeveloperTools")

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var isPro: Bool { dependencies.entitlements.isPro }

    func alertUsageText(for items: [TrackedItem]) -> String {
        let used = items.filter(\.isNotificationEnabled).count
        return isPro ? "\(used) (unlimited)" : "\(used) of \(NotificationManager.freeAlertLimit)"
    }

    func refreshPendingCount() async {
        pendingAlertCount = await dependencies.notifications.pendingAlertCount()
    }

    func resyncReminders(in context: ModelContext) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        let result = await ReminderSyncService(notifications: dependencies.notifications)
            .resync(isPro: isPro, in: context)
        await refreshPendingCount()
        var message = "Rescheduled \(result.rescheduled) item(s). \(pendingAlertCount) reminder(s) pending."
        if result.disabledOverQuota > 0 {
            message += " Turned off \(result.disabledOverQuota) over the free limit."
        }
        if result.failed > 0 {
            message += " \(result.failed) failed. Check notification permission in the Settings app."
        }
        finish(message)
    }

    func load(_ scenario: DemoScenario, currency: String, into context: ModelContext) {
        let items = DemoDataFactory.items(for: scenario, currency: currency)
        items.forEach { context.insert($0) }
        do {
            try context.save()
            finish("Added \(items.count) items from “\(scenario.title)”.")
        } catch {
            context.rollback()
            errorMessage = "Demo data could not be saved."
        }
    }

    /// Enables reminders on items until the free quota is reached, going through the real scheduler.
    func fillAlertQuota(items: [TrackedItem], in context: ModelContext) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        var activeIDs = Set(items.filter(\.isNotificationEnabled).map(\.id))
        let candidates = items.filter { !$0.isNotificationEnabled && !$0.snapshot.isExpired(now: .now) }
        var enabled = 0

        for item in candidates {
            guard !Task.isCancelled else { break }
            do {
                try await dependencies.notifications.schedule(for: item.snapshot, activeAlertItemIDs: activeIDs, isPro: isPro)
                item.isNotificationEnabled = true
                activeIDs.insert(item.id)
                enabled += 1
            } catch {
                if case .quotaExceeded = error { break }
                errorMessage = error.userMessage
                break
            }
            if !isPro && activeIDs.count >= NotificationManager.freeAlertLimit { break }
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            errorMessage = "Reminder changes could not be saved."
            return
        }
        if candidates.isEmpty {
            finish("No upcoming items without reminders. Load a demo scenario first.")
        } else if enabled == 0 && errorMessage == nil {
            finish("The free reminder quota is already full. Try enabling one more item to see the paywall.")
        } else if errorMessage == nil {
            finish("Turned on reminders for \(enabled) item(s). Alerts in use: \(activeIDs.count).")
        }
    }

    func sendTestAlert() async {
        do {
            try await dependencies.notifications.sendTestAlert(after: Self.testAlertDelaySeconds)
            finish("Test notification scheduled. It arrives in \(Self.testAlertDelaySeconds) seconds, even while Renewly is open.")
        } catch {
            errorMessage = error.userMessage
        }
    }

    func deleteAll(_ items: [TrackedItem], in context: ModelContext) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        let removed = items.map { (id: $0.id, receiptPath: $0.receiptImagePath) }
        items.forEach { context.delete($0) }
        do {
            try context.save()
        } catch {
            context.rollback()
            errorMessage = "Items could not be deleted."
            return
        }

        for entry in removed {
            await dependencies.notifications.cancel(for: entry.id)
            guard let path = entry.receiptPath else { continue }
            do {
                try await dependencies.receipts.delete(relativePath: path)
            } catch {
                logger.error("Receipt cleanup failed: \(error.userMessage, privacy: .public)")
            }
        }
        finish("Deleted \(removed.count) items, their reminders and receipts.")
    }

    private func finish(_ message: String) {
        statusMessage = message
        actionCount += 1
    }
}
#endif
