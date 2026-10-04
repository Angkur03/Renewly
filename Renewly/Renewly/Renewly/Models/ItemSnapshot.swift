//
// ItemSnapshot.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// Immutable, `Sendable` copy of a `TrackedItem` used across isolation boundaries
/// and by pure calculation code, so SwiftData models never leave the main actor.
nonisolated struct ItemSnapshot: Sendable, Hashable, Identifiable {
    static let expiringSoonThresholdDays = 14

    let id: UUID
    let title: String
    let category: ItemCategory
    let cost: Double
    let currencyCode: String
    let expirationDate: Date
    let billingCycle: BillingCycle
    let isNotificationEnabled: Bool

    var monthlyCost: Double {
        category == .subscription ? billingCycle.monthlyEquivalent(of: cost) : 0
    }

    func daysUntilExpiration(from now: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: expirationDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    func isExpired(now: Date, calendar: Calendar = .current) -> Bool {
        daysUntilExpiration(from: now, calendar: calendar) < 0
    }

    func isExpiringSoon(now: Date, calendar: Calendar = .current) -> Bool {
        let days = daysUntilExpiration(from: now, calendar: calendar)
        return days >= 0 && days < Self.expiringSoonThresholdDays
    }
}
