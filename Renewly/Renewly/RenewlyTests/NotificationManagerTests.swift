//
// NotificationManagerTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

actor FakeNotificationCenter: NotificationCenterClient {
    var status: NotificationAuthorization
    var grantOnRequest: Bool
    var failOnAdd = false
    var addDelay: Duration?
    private(set) var added: [ScheduledAlert] = []
    private(set) var removed: [String] = []
    private(set) var authorizationRequests = 0

    init(status: NotificationAuthorization = .authorized, grantOnRequest: Bool = true) {
        self.status = status
        self.grantOnRequest = grantOnRequest
    }

    func configure(failOnAdd: Bool = false, addDelay: Duration? = nil) {
        self.failOnAdd = failOnAdd
        self.addDelay = addDelay
    }

    func authorizationStatus() async -> NotificationAuthorization { status }

    func requestAuthorization() async throws -> Bool {
        authorizationRequests += 1
        status = grantOnRequest ? .authorized : .denied
        return grantOnRequest
    }

    func add(_ alert: ScheduledAlert) async throws {
        if let addDelay {
            try await Task.sleep(for: addDelay)
        }
        if failOnAdd {
            throw CancellationError()
        }
        added.append(alert)
    }

    func removePendingAlerts(withIdentifiers identifiers: [String]) async {
        removed.append(contentsOf: identifiers)
        added.removeAll { identifiers.contains($0.identifier) }
    }

    func pendingAlertIdentifiers() async -> [String] {
        added.map(\.identifier)
    }
}

@Suite("NotificationManager")
struct NotificationManagerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private var referenceNow: Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12)) ?? .distantPast
    }

    private func makeItem(id: UUID = UUID(), daysUntilExpiration: Int) -> ItemSnapshot {
        let expiration = calendar.date(byAdding: .day, value: daysUntilExpiration, to: referenceNow) ?? referenceNow
        return ItemSnapshot(
            id: id,
            title: "Netflix",
            category: .subscription,
            cost: 15,
            currencyCode: "USD",
            expirationDate: expiration,
            billingCycle: .monthly,
            isNotificationEnabled: true
        )
    }

    private func makeManager(
        center: FakeNotificationCenter,
        preferences: ReminderPreferences = ReminderPreferences()
    ) -> NotificationManager {
        let now = referenceNow
        return NotificationManager(
            center: center,
            calendar: calendar,
            preferences: FixedReminderPreferences(preferences),
            now: { now }
        )
    }

    // MARK: Quota

    @Test("Free users can enable alerts while fewer than three items are active")
    func allowsBelowFreeLimit() {
        let manager = makeManager(center: FakeNotificationCenter())
        let active: Set<UUID> = [UUID(), UUID()]
        #expect(manager.canEnableAlerts(for: UUID(), activeAlertItemIDs: active, isPro: false))
    }

    @Test("Free users hit the quota at three active items")
    func throwsAtFreeLimit() async {
        let center = FakeNotificationCenter()
        let manager = makeManager(center: center)
        let active: Set<UUID> = [UUID(), UUID(), UUID()]

        await #expect(throws: NotificationError.quotaExceeded(limit: 3)) {
            try await manager.schedule(for: makeItem(daysUntilExpiration: 60), activeAlertItemIDs: active, isPro: false)
        }
        #expect(await center.added.isEmpty)
    }

    @Test("Editing an item that already has alerts does not count against the quota")
    func editingExistingAlertItemIsAllowed() async throws {
        let itemID = UUID()
        let center = FakeNotificationCenter()
        let manager = makeManager(center: center)
        let active: Set<UUID> = [itemID, UUID(), UUID()]

        try await manager.schedule(for: makeItem(id: itemID, daysUntilExpiration: 60), activeAlertItemIDs: active, isPro: false)
        #expect(await center.added.count == 4)
    }

    @Test("Pro users have no quota")
    func proHasNoLimit() async throws {
        let center = FakeNotificationCenter()
        let manager = makeManager(center: center)
        let active = Set((0..<20).map { _ in UUID() })

        try await manager.schedule(for: makeItem(daysUntilExpiration: 60), activeAlertItemIDs: active, isPro: true)
        #expect(await center.added.count == 4)
    }

    // MARK: Scheduling

    @Test("Schedules 30, 7, 3 and 1 day reminders at 09:00 with stable identifiers")
    func schedulesThreeRemindersAtNine() async throws {
        let center = FakeNotificationCenter()
        let manager = makeManager(center: center)
        let item = makeItem(daysUntilExpiration: 60)

        try await manager.schedule(for: item, activeAlertItemIDs: [], isPro: false)

        let added = await center.added
        #expect(added.map(\.identifier) == [
            "\(item.id.uuidString)-30d",
            "\(item.id.uuidString)-7d",
            "\(item.id.uuidString)-3d",
            "\(item.id.uuidString)-1d"
        ])
        #expect(added.allSatisfy { $0.fireDateComponents?.hour == 9 && $0.fireDateComponents?.minute == 0 })

        let expirationDay = calendar.startOfDay(for: item.expirationDate)
        let firstFire = try #require(added.first?.fireDateComponents.flatMap { calendar.date(from: $0) })
        let expectedFirst = calendar.date(byAdding: .day, value: -30, to: expirationDay).flatMap {
            calendar.date(bySettingHour: 9, minute: 0, second: 0, of: $0)
        }
        #expect(firstFire == expectedFirst)
    }

    @Test("Reminders whose date has already passed are skipped")
    func skipsPastReminders() {
        let manager = makeManager(center: FakeNotificationCenter())
        let item = makeItem(daysUntilExpiration: 5)

        let alerts = manager.alerts(for: item)
        #expect(alerts.map(\.identifier) == ["\(item.id.uuidString)-3d", "\(item.id.uuidString)-1d"])
    }

    @Test("Rescheduling replaces existing reminders instead of duplicating them")
    func rescheduleCancelsFirst() async throws {
        let center = FakeNotificationCenter()
        let manager = makeManager(center: center)
        let item = makeItem(daysUntilExpiration: 60)

        try await manager.schedule(for: item, activeAlertItemIDs: [], isPro: false)
        try await manager.schedule(for: item, activeAlertItemIDs: [item.id], isPro: false)

        #expect(await center.added.count == 4)
        #expect(await center.removed.count == 2 * NotificationManager.identifiers(for: item.id).count)
    }

    @Test("Cancel removes every reminder identifier for the item")
    func cancelRemovesAllIdentifiers() async throws {
        let center = FakeNotificationCenter()
        let manager = makeManager(center: center)
        let item = makeItem(daysUntilExpiration: 60)

        try await manager.schedule(for: item, activeAlertItemIDs: [], isPro: false)
        await manager.cancel(for: item.id)

        #expect(await center.added.isEmpty)
        #expect(Set(await center.removed) == Set(NotificationManager.identifiers(for: item.id)))
    }

    // MARK: Preferences

    @Test("Reminders switched off in Settings only cancel and never prompt")
    func disabledPreferencesCancelOnly() async throws {
        let center = FakeNotificationCenter(status: .notDetermined)
        let manager = makeManager(center: center, preferences: ReminderPreferences(isEnabled: false))
        let item = makeItem(daysUntilExpiration: 60)

        try await manager.schedule(for: item, activeAlertItemIDs: [], isPro: false)

        #expect(await center.added.isEmpty)
        #expect(await center.authorizationRequests == 0)
        #expect(Set(await center.removed) == Set(NotificationManager.identifiers(for: item.id)))
    }

    @Test("Only the chosen offsets are scheduled, and 3 days is always kept")
    func customOffsetsKeepThreeDays() async throws {
        let center = FakeNotificationCenter()
        let manager = makeManager(center: center, preferences: ReminderPreferences(offsets: [30]))
        let item = makeItem(daysUntilExpiration: 60)

        try await manager.schedule(for: item, activeAlertItemIDs: [], isPro: false)

        #expect(await center.added.map(\.identifier) == ["\(item.id.uuidString)-30d", "\(item.id.uuidString)-3d"])
    }

    // MARK: Missed 3-day window

    @Test("Saving inside the last 3 days after 9:00 delivers one alert right away", arguments: [3, 2, 1, 0])
    func deliversMissedReminder(daysLeft: Int) throws {
        let manager = makeManager(center: FakeNotificationCenter())
        let item = makeItem(daysUntilExpiration: daysLeft)

        let alerts = manager.alerts(for: item, deliverMissedReminder: true)

        let missed = try #require(alerts.last)
        #expect(missed.identifier == NotificationManager.missedIdentifier(for: item.id))
        #expect(missed.trigger == .after(seconds: NotificationManager.missedReminderDelay))
        let expectedPhrase = switch daysLeft {
        case 0: "today"
        case 1: "tomorrow"
        default: "in \(daysLeft) days"
        }
        #expect(missed.body.contains(expectedPhrase))
        #expect(alerts.filter { $0.identifier.hasSuffix("-now") }.count == 1)
    }

    @Test("No immediate alert when today's reminder is still ahead")
    func noMissedReminderBeforeNine() throws {
        let morning = try #require(calendar.date(bySettingHour: 8, minute: 0, second: 0, of: referenceNow))
        let manager = NotificationManager(
            center: FakeNotificationCenter(),
            calendar: calendar,
            preferences: FixedReminderPreferences(),
            now: { morning }
        )
        let item = makeItem(daysUntilExpiration: 3)

        let alerts = manager.alerts(for: item, deliverMissedReminder: true)
        #expect(alerts.map(\.identifier) == ["\(item.id.uuidString)-3d", "\(item.id.uuidString)-1d"])
    }

    @Test("No immediate alert outside the 3-day window, after expiry, or during resync", arguments: [10, -1])
    func noMissedReminderOutsideWindow(daysLeft: Int) {
        let manager = makeManager(center: FakeNotificationCenter())
        let item = makeItem(daysUntilExpiration: daysLeft)
        #expect(!manager.alerts(for: item, deliverMissedReminder: true).contains { $0.identifier.hasSuffix("-now") })
        #expect(!manager.alerts(for: makeItem(daysUntilExpiration: 2)).contains { $0.identifier.hasSuffix("-now") })
    }

    // MARK: Authorization & errors

    @Test("Denied permission maps to notAuthorized")
    func deniedPermissionThrows() async {
        let manager = makeManager(center: FakeNotificationCenter(status: .denied))
        await #expect(throws: NotificationError.notAuthorized) {
            try await manager.schedule(for: makeItem(daysUntilExpiration: 60), activeAlertItemIDs: [], isPro: false)
        }
    }

    @Test("Undetermined permission prompts once and schedules when granted")
    func promptsWhenUndetermined() async throws {
        let center = FakeNotificationCenter(status: .notDetermined, grantOnRequest: true)
        let manager = makeManager(center: center)

        try await manager.schedule(for: makeItem(daysUntilExpiration: 60), activeAlertItemIDs: [], isPro: false)
        #expect(await center.authorizationRequests == 1)
        #expect(await center.added.count == 4)
    }

    @Test("A failing add maps to schedulingFailed and leaves nothing pending")
    func addFailureMapsToSchedulingFailed() async {
        let center = FakeNotificationCenter()
        await center.configure(failOnAdd: true)
        let manager = makeManager(center: center)

        await #expect(throws: NotificationError.schedulingFailed) {
            try await manager.schedule(for: makeItem(daysUntilExpiration: 60), activeAlertItemIDs: [], isPro: false)
        }
        #expect(await center.added.isEmpty)
    }

    @Test("Test alert fires the requested number of seconds from now")
    func testAlertFiresAfterDelay() async throws {
        let center = FakeNotificationCenter()
        let manager = makeManager(center: center)

        try await manager.sendTestAlert(after: 5)

        let alert = try #require(await center.added.first)
        #expect(alert.identifier.hasPrefix("test-"))
        #expect(alert.trigger == .after(seconds: 5))
    }

    @Test("Test alert requires permission")
    func testAlertRequiresPermission() async {
        let manager = makeManager(center: FakeNotificationCenter(status: .denied))
        await #expect(throws: NotificationError.notAuthorized) {
            try await manager.sendTestAlert(after: 5)
        }
    }

    @Test("Cancelling the scheduling task throws cancelled and cleans up")
    func cancellationIsCooperative() async {
        let center = FakeNotificationCenter()
        await center.configure(addDelay: .seconds(5))
        let manager = makeManager(center: center)
        let item = makeItem(daysUntilExpiration: 60)

        let task = Task { () -> NotificationError? in
            do throws(NotificationError) {
                try await manager.schedule(for: item, activeAlertItemIDs: [], isPro: false)
                return nil
            } catch {
                return error
            }
        }
        task.cancel()

        #expect(await task.value == .cancelled)
        #expect(await center.added.isEmpty)
    }
}
