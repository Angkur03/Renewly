//
// TimeLeftProgress.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// How far through the current billing period (subscriptions) or coverage window (warranties) an item is.
nonisolated struct TimeLeftProgress: Equatable, Sendable {
    /// 0 at the start of the period, 1 at (or past) the end.
    let elapsedFraction: Double
    let daysLeft: Int
    let totalDays: Int

    var remainingFraction: Double { 1 - elapsedFraction }

    static func make(
        category: ItemCategory,
        billingCycle: BillingCycle,
        startDate: Date,
        expirationDate: Date,
        now: Date,
        isTrial: Bool = false,
        calendar: Calendar = .current
    ) -> TimeLeftProgress {
        // A trial runs from sign-up to the first charge, not a full billing cycle.
        let periodStart = category == .subscription && !isTrial
            ? billingCycle.periodStart(endingAt: expirationDate, calendar: calendar)
            : startDate
        let start = calendar.startOfDay(for: periodStart)
        let end = calendar.startOfDay(for: expirationDate)
        let today = calendar.startOfDay(for: now)

        let totalDays = max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
        let daysLeft = calendar.dateComponents([.day], from: today, to: end).day ?? 0

        let elapsed: Double
        if totalDays == 0 {
            elapsed = daysLeft > 0 ? 0 : 1
        } else {
            let elapsedDays = calendar.dateComponents([.day], from: start, to: today).day ?? 0
            elapsed = min(1, max(0, Double(elapsedDays) / Double(totalDays)))
        }
        return TimeLeftProgress(elapsedFraction: elapsed, daysLeft: daysLeft, totalDays: totalDays)
    }
}
