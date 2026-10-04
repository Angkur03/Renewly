//
// ReminderSyncServiceTests.swift
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
@Suite("Reminder resync")
struct ReminderSyncServiceTests {
    private func makeContext(alertItemCount: Int) throws -> ModelContext {
        let container = try ModelContainer(
            for: TrackedItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        for index in 0..<alertItemCount {
            context.insert(TrackedItem(
                title: "Item \(index)",
                category: .subscription,
                cost: 9.99,
                currencyCode: "USD",
                startDate: .now,
                expirationDate: .now.addingTimeInterval(86_400 * Double(60 + index)),
                isNotificationEnabled: true
            ))
        }
        context.insert(TrackedItem(
            title: "Silent",
            category: .warranty,
            cost: 100,
            currencyCode: "USD",
            startDate: .now,
            expirationDate: .now.addingTimeInterval(86_400 * 90)
        ))
        try context.save()
        return context
    }

    private func enabledTitles(in context: ModelContext) throws -> [String] {
        let descriptor = FetchDescriptor<TrackedItem>(
            predicate: #Predicate { $0.isNotificationEnabled },
            sortBy: [SortDescriptor(\.expirationDate)]
        )
        return try context.fetch(descriptor).map(\.title)
    }

    @Test("Free tier keeps the 3 soonest items and disables the rest")
    func freeTierQuota() async throws {
        let context = try makeContext(alertItemCount: 5)
        let center = FakeNotificationCenter()
        let service = ReminderSyncService(notifications: NotificationManager(center: center, preferences: FixedReminderPreferences()))

        let result = await service.resync(isPro: false, in: context)

        #expect(result == ReminderSyncResult(rescheduled: 3, disabledOverQuota: 2, failed: 0))
        #expect(try enabledTitles(in: context) == ["Item 0", "Item 1", "Item 2"])
        let pending = await center.pendingAlertIdentifiers()
        #expect(pending.count == 3)
        #expect(pending.allSatisfy { $0.hasSuffix("-7d") })
    }

    @Test("Pro reschedules every item with alerts")
    func proReschedulesAll() async throws {
        let context = try makeContext(alertItemCount: 5)
        let center = FakeNotificationCenter()
        let service = ReminderSyncService(notifications: NotificationManager(center: center, preferences: FixedReminderPreferences()))

        let result = await service.resync(isPro: true, in: context)

        #expect(result == ReminderSyncResult(rescheduled: 5, disabledOverQuota: 0, failed: 0))
        #expect(try enabledTitles(in: context).count == 5)
        #expect(await center.pendingAlertIdentifiers().count == 5 * NotificationManager.reminderOffsets.count)
    }

    @Test("Switching reminders off in Settings clears the queue but keeps item choices")
    func globallyDisabled() async throws {
        let context = try makeContext(alertItemCount: 2)
        let center = FakeNotificationCenter()
        let enabled = ReminderSyncService(notifications: NotificationManager(center: center, preferences: FixedReminderPreferences()))
        await enabled.resync(isPro: true, in: context)
        #expect(await center.pendingAlertIdentifiers().isEmpty == false)

        let disabled = ReminderSyncService(notifications: NotificationManager(
            center: center,
            preferences: FixedReminderPreferences(ReminderPreferences(isEnabled: false))
        ))
        await disabled.resync(isPro: true, in: context)

        #expect(await center.pendingAlertIdentifiers().isEmpty)
        #expect(try enabledTitles(in: context).count == 2)
    }

    @Test("Denied permission counts as failures without disabling items")
    func deniedPermission() async throws {
        let context = try makeContext(alertItemCount: 2)
        let center = FakeNotificationCenter(status: .denied, grantOnRequest: false)
        let service = ReminderSyncService(notifications: NotificationManager(center: center, preferences: FixedReminderPreferences()))

        let result = await service.resync(isPro: false, in: context)

        #expect(result.rescheduled == 0)
        #expect(result.disabledOverQuota == 0)
        #expect(try enabledTitles(in: context).count == 2)
    }
}
