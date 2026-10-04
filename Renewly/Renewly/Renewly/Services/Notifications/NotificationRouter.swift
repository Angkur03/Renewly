//
// NotificationRouter.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation

/// Hands navigation requests from outside the UI (tapped notifications, widgets, Siri and Shortcuts) to `RootView`.
/// Requests can arrive before the UI exists (cold launch), so each one waits here until it is consumed.
@Observable
@MainActor
final class NotificationRouter {
    /// The app's single inbox. App Intents run without access to the SwiftUI hierarchy, so they reach it here.
    static let shared = NotificationRouter()

    private(set) var pendingItemID: UUID?
    private(set) var pendingNewItem: ItemCategory?

    func open(itemID: UUID) {
        pendingItemID = itemID
    }

    /// Returns the waiting item once and clears it, so a later view update cannot replay the navigation.
    func consume() -> UUID? {
        defer { pendingItemID = nil }
        return pendingItemID
    }

    func requestNewItem(_ category: ItemCategory) {
        pendingNewItem = category
    }

    func consumeNewItemRequest() -> ItemCategory? {
        defer { pendingNewItem = nil }
        return pendingNewItem
    }
}
