//
// NotificationManager.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import UserNotifications

nonisolated final class NotificationManager: NotificationScheduling {
    static let freeAlertLimit = 3
    static let reminderOffsets = ReminderPreferences.availableOffsets
    static let reminderHour = 9
    static let missedReminderDelay: TimeInterval = 5

    private let center: any NotificationCenterClient
    private let calendar: Calendar
    private let preferences: any ReminderPreferencesProviding
    private let now: @Sendable () -> Date

    init(
        center: any NotificationCenterClient = LiveNotificationCenter(),
        calendar: Calendar = .current,
        preferences: any ReminderPreferencesProviding = UserDefaultsReminderPreferences(),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.center = center
        self.calendar = calendar
        self.preferences = preferences
        self.now = now
    }

    func authorizationStatus() async -> NotificationAuthorization {
        await center.authorizationStatus()
    }

    func requestAuthorization() async throws(NotificationError) -> Bool {
        switch await center.authorizationStatus() {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization()
            } catch {
                throw .notAuthorized
            }
        }
    }

    func canEnableAlerts(for itemID: UUID, activeAlertItemIDs: Set<UUID>, isPro: Bool) -> Bool {
        isPro || activeAlertItemIDs.subtracting([itemID]).count < Self.freeAlertLimit
    }

    func schedule(
        for item: ItemSnapshot,
        activeAlertItemIDs: Set<UUID>,
        isPro: Bool,
        deliverMissedReminder: Bool
    ) async throws(NotificationError) {
        guard canEnableAlerts(for: item.id, activeAlertItemIDs: activeAlertItemIDs, isPro: isPro) else {
            throw .quotaExceeded(limit: Self.freeAlertLimit)
        }
        let preferences = preferences.current().limited(isPro: isPro)
        guard preferences.isEnabled else {
            await cancel(for: item.id)
            return
        }
        guard try await requestAuthorization() else {
            throw .notAuthorized
        }

        await cancel(for: item.id)

        for alert in alerts(for: item, preferences: preferences, deliverMissedReminder: deliverMissedReminder) {
            guard !Task.isCancelled else {
                await cancel(for: item.id)
                throw .cancelled
            }
            do {
                try await center.add(alert)
            } catch {
                await cancel(for: item.id)
                throw Task.isCancelled ? .cancelled : .schedulingFailed
            }
        }
    }

    func cancel(for itemID: UUID) async {
        await center.removePendingAlerts(withIdentifiers: Self.identifiers(for: itemID))
    }

    func sendTestAlert(after seconds: Int) async throws(NotificationError) {
        guard try await requestAuthorization() else { throw .notAuthorized }
        let alert = ScheduledAlert(
            identifier: "test-\(UUID().uuidString)",
            title: "Renewly test reminder",
            body: "Notifications are working. Real reminders arrive at 9:00 AM.",
            trigger: .after(seconds: TimeInterval(max(seconds, 1)))
        )
        do {
            try await center.add(alert)
        } catch {
            throw .schedulingFailed
        }
    }

    func pendingAlertCount() async -> Int {
        await center.pendingAlertIdentifiers().count
    }

    func alerts(
        for item: ItemSnapshot,
        preferences: ReminderPreferences = ReminderPreferences(),
        deliverMissedReminder: Bool = false
    ) -> [ScheduledAlert] {
        let currentDate = now()
        let expirationDay = calendar.startOfDay(for: item.expirationDate)

        let scheduled = preferences.offsets.compactMap { daysBefore -> ScheduledAlert? in
            guard let reminderDay = calendar.date(byAdding: .day, value: -daysBefore, to: expirationDay),
                  let fireDate = calendar.date(bySettingHour: Self.reminderHour, minute: 0, second: 0, of: reminderDay),
                  fireDate > currentDate else {
                return nil
            }
            return ScheduledAlert(
                identifier: Self.identifier(for: item.id, daysBefore: daysBefore),
                title: item.title,
                body: Self.body(for: item.category, daysBefore: daysBefore),
                trigger: .date(calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate))
            )
        }

        guard deliverMissedReminder,
              let missed = missedReminder(for: item, expirationDay: expirationDay, now: currentDate, scheduled: scheduled) else {
            return scheduled
        }
        return scheduled + [missed]
    }

    /// Inside the final 3 days, a reminder whose 9:00 slot already passed would never fire,
    /// so the user gets one alert right away instead.
    private func missedReminder(
        for item: ItemSnapshot,
        expirationDay: Date,
        now currentDate: Date,
        scheduled: [ScheduledAlert]
    ) -> ScheduledAlert? {
        guard let daysLeft = calendar.dateComponents([.day], from: calendar.startOfDay(for: currentDate), to: expirationDay).day,
              (0...ReminderPreferences.requiredOffset).contains(daysLeft) else {
            return nil
        }
        let todaysIdentifier = Self.identifier(for: item.id, daysBefore: daysLeft)
        guard !scheduled.contains(where: { $0.identifier == todaysIdentifier }) else { return nil }
        return ScheduledAlert(
            identifier: Self.missedIdentifier(for: item.id),
            title: item.title,
            body: Self.body(for: item.category, daysBefore: daysLeft),
            trigger: .after(seconds: Self.missedReminderDelay)
        )
    }

    static func identifier(for itemID: UUID, daysBefore: Int) -> String {
        "\(itemID.uuidString)-\(daysBefore)d"
    }

    static func missedIdentifier(for itemID: UUID) -> String {
        "\(itemID.uuidString)-now"
    }

    static func identifiers(for itemID: UUID) -> [String] {
        reminderOffsets.map { identifier(for: itemID, daysBefore: $0) } + [missedIdentifier(for: itemID)]
    }

    private static func body(for category: ItemCategory, daysBefore: Int) -> String {
        let timeframe = switch daysBefore {
        case 0: "today"
        case 1: "tomorrow"
        default: "in \(daysBefore) days"
        }
        switch category {
        case .subscription:
            return "Renews \(timeframe). Cancel now if you no longer need it."
        case .warranty:
            return "Warranty expires \(timeframe). File any claims before it ends."
        }
    }
}

nonisolated struct LiveNotificationCenter: NotificationCenterClient {
    private var center: UNUserNotificationCenter { .current() }

    func authorizationStatus() async -> NotificationAuthorization {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func add(_ alert: ScheduledAlert) async throws {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.body
        content.sound = .default

        let trigger: UNNotificationTrigger
        switch alert.trigger {
        case .date(let components):
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .after(let seconds):
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        }
        let request = UNNotificationRequest(identifier: alert.identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    func removePendingAlerts(withIdentifiers identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func pendingAlertIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }
}
