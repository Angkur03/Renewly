//
// DemoNotificationCenter.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

#if DEBUG
import Foundation

/// Stands in for the system notification center during demo runs, so seeded reminders look active
/// without a permission alert covering the screen.
actor DemoNotificationCenter: NotificationCenterClient {
    private var pending: Set<String> = []

    func authorizationStatus() async -> NotificationAuthorization {
        .authorized
    }

    func requestAuthorization() async throws -> Bool {
        true
    }

    func add(_ alert: ScheduledAlert) async throws {
        pending.insert(alert.identifier)
    }

    func removePendingAlerts(withIdentifiers identifiers: [String]) async {
        pending.subtract(identifiers)
    }

    func pendingAlertIdentifiers() async -> [String] {
        Array(pending)
    }
}
#endif
