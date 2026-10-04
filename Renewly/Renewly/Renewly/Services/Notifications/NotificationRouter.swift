//
// NotificationRouter.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation

/// Hands the item behind a tapped notification from the notification-center delegate to the UI.
/// Taps can arrive before the UI exists (cold launch), so the request waits here until `RootView` consumes it.
@Observable
@MainActor
final class NotificationRouter {
    private(set) var pendingItemID: UUID?

    func open(itemID: UUID) {
        pendingItemID = itemID
    }

    /// Returns the waiting item once and clears it, so a later view update cannot replay the navigation.
    func consume() -> UUID? {
        defer { pendingItemID = nil }
        return pendingItemID
    }
}
