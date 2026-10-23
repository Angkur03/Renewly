//
// NotificationError.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum NotificationError: Error, Equatable, Sendable {
    case quotaExceeded(limit: Int)
    case notAuthorized
    case schedulingFailed
    case cancelled

    var userMessage: String {
        switch self {
        case .quotaExceeded(let limit):
            String(localized: "The free plan includes reminders for up to \(limit) items. Upgrade to Pro for unlimited reminders.")
        case .notAuthorized:
            String(localized: "Notifications are turned off for Renewly. Enable them in the Settings app to receive reminders.")
        case .schedulingFailed:
            String(localized: "Reminders could not be scheduled. Please try again.")
        case .cancelled:
            String(localized: "Scheduling reminders was cancelled.")
        }
    }
}
