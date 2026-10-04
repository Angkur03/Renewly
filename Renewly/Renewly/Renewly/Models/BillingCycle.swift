//
// BillingCycle.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum BillingCycle: String, CaseIterable, Identifiable, Sendable {
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .yearly: "Yearly"
        }
    }

    var shortSuffix: String {
        switch self {
        case .monthly: "/mo"
        case .quarterly: "/qtr"
        case .yearly: "/yr"
        }
    }

    var monthsPerCycle: Int {
        switch self {
        case .monthly: 1
        case .quarterly: 3
        case .yearly: 12
        }
    }

    func monthlyEquivalent(of cost: Double) -> Double {
        cost / Double(monthsPerCycle)
    }

    /// The first renewal falling on or after the day of `now`. Each candidate is computed from the
    /// original `anchor` (not the previous candidate) so month-end dates do not drift: Jan 31 → Feb 28 → Mar 31.
    func nextRenewal(from anchor: Date, onOrAfter now: Date, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        guard calendar.startOfDay(for: anchor) < today else { return anchor }

        let elapsedMonths = calendar.dateComponents([.month], from: anchor, to: today).month ?? 0
        var step = max(1, elapsedMonths / monthsPerCycle)
        let maxSteps = step + 1_200 / monthsPerCycle
        while step <= maxSteps {
            guard let candidate = calendar.date(byAdding: .month, value: step * monthsPerCycle, to: anchor) else {
                return anchor
            }
            if calendar.startOfDay(for: candidate) >= today {
                return candidate
            }
            step += 1
        }
        return anchor
    }

    /// Start of the billing period that ends on `renewal`.
    func periodStart(endingAt renewal: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: -monthsPerCycle, to: renewal) ?? renewal
    }
}
