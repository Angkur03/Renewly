//
// NotificationScheduling.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum NotificationAuthorization: Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
}

nonisolated enum AlertTrigger: Sendable, Equatable {
    case date(DateComponents)
    case after(seconds: TimeInterval)
}

nonisolated struct ScheduledAlert: Sendable, Equatable {
    static let itemIDKey = "itemID"

    let identifier: String
    let title: String
    let body: String
    let trigger: AlertTrigger
    /// The tracked item the alert is about; tapping the notification opens it.
    let itemID: UUID?

    init(identifier: String, title: String, body: String, trigger: AlertTrigger, itemID: UUID? = nil) {
        self.identifier = identifier
        self.title = title
        self.body = body
        self.trigger = trigger
        self.itemID = itemID
    }

    var userInfo: [String: String] {
        itemID.map { [Self.itemIDKey: $0.uuidString] } ?? [:]
    }

    static func itemID(from userInfo: [AnyHashable: Any]) -> UUID? {
        guard let raw = userInfo[itemIDKey] as? String else { return nil }
        return UUID(uuidString: raw)
    }

    var fireDateComponents: DateComponents? {
        guard case .date(let components) = trigger else { return nil }
        return components
    }
}

/// Thin seam over `UNUserNotificationCenter` so scheduling logic can be unit tested.
nonisolated protocol NotificationCenterClient: Sendable {
    func authorizationStatus() async -> NotificationAuthorization
    func requestAuthorization() async throws -> Bool
    func add(_ alert: ScheduledAlert) async throws
    func removePendingAlerts(withIdentifiers identifiers: [String]) async
    func pendingAlertIdentifiers() async -> [String]
}

nonisolated protocol NotificationScheduling: Sendable {
    func authorizationStatus() async -> NotificationAuthorization
    func requestAuthorization() async throws(NotificationError) -> Bool
    func canEnableAlerts(for itemID: UUID, activeAlertItemIDs: Set<UUID>, isPro: Bool) -> Bool
    /// Replaces the item's pending reminders. When reminders are switched off in Settings this only cancels.
    /// - Parameter deliverMissedReminder: When the item is already inside its catch-up window and today's
    ///   reminder time has passed, also deliver one alert right away. Use for explicit user saves only,
    ///   so background resyncs never repeat it.
    func schedule(
        for item: ItemSnapshot,
        activeAlertItemIDs: Set<UUID>,
        isPro: Bool,
        deliverMissedReminder: Bool
    ) async throws(NotificationError)
    func cancel(for itemID: UUID) async
    /// Fires a one-off alert shortly after the call so delivery can be verified on device.
    func sendTestAlert(after seconds: Int) async throws(NotificationError)
    func pendingAlertCount() async -> Int
}

extension NotificationScheduling {
    nonisolated func schedule(for item: ItemSnapshot, activeAlertItemIDs: Set<UUID>, isPro: Bool) async throws(NotificationError) {
        try await schedule(for: item, activeAlertItemIDs: activeAlertItemIDs, isPro: isPro, deliverMissedReminder: false)
    }
}
