//
// SpendingInsights.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated struct RenewalCharge: Identifiable, Equatable, Sendable {
    let itemID: UUID
    let title: String
    let amount: Double
    let date: Date

    var id: String { "\(itemID.uuidString)-\(date.timeIntervalSinceReferenceDate)" }
}

nonisolated struct MonthlySpend: Identifiable, Equatable, Sendable {
    /// First day of the month.
    let month: Date
    let amount: Double

    var id: Date { month }
}

nonisolated struct CostShare: Identifiable, Equatable, Sendable {
    let title: String
    let monthlyAmount: Double
    let fraction: Double
    let isOther: Bool

    var id: String { isOther ? "other" : title }
}

nonisolated struct WarrantyCoverage: Equatable, Sendable {
    let activeCount: Int
    let protectedValue: Double
    let expiringSoonCount: Int
    let expiredCount: Int
}

/// Spending and coverage figures for one currency. Items in other currencies are counted in
/// `excludedItemCount` but never mixed into totals, since there is no exchange-rate source.
nonisolated struct SpendingInsights: Equatable, Sendable {
    static let upcomingWindowDays = 30
    static let projectionMonths = 12
    static let warrantyExpiringWindowDays = 90
    static let maxShareSlices = 5

    let currencyCode: String
    let subscriptionCount: Int
    let monthlyTotal: Double
    let upcomingCharges: [RenewalCharge]
    let projection: [MonthlySpend]
    let shares: [CostShare]
    let warranties: WarrantyCoverage
    let excludedItemCount: Int

    var yearlyTotal: Double { monthlyTotal * 12 }
    var dailyAverage: Double { yearlyTotal / 365 }
    var upcomingTotal: Double { upcomingCharges.reduce(0) { $0 + $1.amount } }
    var projectionTotal: Double { projection.reduce(0) { $0 + $1.amount } }
    var peakMonth: MonthlySpend? { projection.max { $0.amount < $1.amount } }
    var isEmpty: Bool { subscriptionCount == 0 && warranties.activeCount == 0 && warranties.expiredCount == 0 }

    static func make(
        from items: [ItemSnapshot],
        currencyCode: String,
        now: Date,
        calendar: Calendar = .current
    ) -> SpendingInsights {
        let matching = items.filter { $0.currencyCode == currencyCode }
        let subscriptions = matching.filter { $0.category == .subscription }
        let warrantyItems = matching.filter { $0.category == .warranty }

        let today = calendar.startOfDay(for: now)
        let monthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
        let projectionEnd = calendar.date(byAdding: .month, value: projectionMonths, to: monthStart) ?? today
        let upcomingEnd = calendar.date(byAdding: .day, value: upcomingWindowDays + 1, to: today) ?? today

        let charges = subscriptions
            .flatMap { renewals(of: $0, from: today, before: projectionEnd, calendar: calendar) }
            .sorted { $0.date < $1.date }

        return SpendingInsights(
            currencyCode: currencyCode,
            subscriptionCount: subscriptions.count,
            monthlyTotal: subscriptions.reduce(0) { $0 + $1.monthlyCost },
            upcomingCharges: charges.filter { $0.date < upcomingEnd },
            projection: projection(of: charges, from: monthStart, calendar: calendar),
            shares: shares(of: subscriptions),
            warranties: coverage(of: warrantyItems, now: now, calendar: calendar),
            excludedItemCount: items.count - matching.count
        )
    }

    /// Every renewal of `item` in `[start, end)`. Dates are stepped from the stored renewal so month-end days don't drift.
    static func renewals(of item: ItemSnapshot, from start: Date, before end: Date, calendar: Calendar) -> [RenewalCharge] {
        let cycle = item.billingCycle
        let first = cycle.nextRenewal(from: item.expirationDate, onOrAfter: start, calendar: calendar)
        var charges: [RenewalCharge] = []
        var step = 0
        while let date = calendar.date(byAdding: .month, value: step * cycle.monthsPerCycle, to: first), date < end {
            if calendar.startOfDay(for: date) >= start {
                charges.append(RenewalCharge(itemID: item.id, title: item.title, amount: item.cost, date: date))
            }
            step += 1
        }
        return charges
    }

    private static func projection(of charges: [RenewalCharge], from monthStart: Date, calendar: Calendar) -> [MonthlySpend] {
        (0..<projectionMonths).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: offset, to: monthStart),
                  let next = calendar.date(byAdding: .month, value: 1, to: month) else { return nil }
            let amount = charges.filter { $0.date >= month && $0.date < next }.reduce(0) { $0 + $1.amount }
            return MonthlySpend(month: month, amount: amount)
        }
    }

    private static func shares(of subscriptions: [ItemSnapshot]) -> [CostShare] {
        let total = subscriptions.reduce(0) { $0 + $1.monthlyCost }
        guard total > 0 else { return [] }

        let sorted = subscriptions.sorted { $0.monthlyCost > $1.monthlyCost }
        let needsOther = sorted.count > maxShareSlices
        let top = needsOther ? Array(sorted.prefix(maxShareSlices - 1)) : sorted
        var result = top.map {
            CostShare(title: $0.title, monthlyAmount: $0.monthlyCost, fraction: $0.monthlyCost / total, isOther: false)
        }
        if needsOther {
            let rest = sorted.dropFirst(top.count).reduce(0) { $0 + $1.monthlyCost }
            result.append(CostShare(title: "Other", monthlyAmount: rest, fraction: rest / total, isOther: true))
        }
        return result
    }

    private static func coverage(of warranties: [ItemSnapshot], now: Date, calendar: Calendar) -> WarrantyCoverage {
        let active = warranties.filter { !$0.isExpired(now: now, calendar: calendar) }
        return WarrantyCoverage(
            activeCount: active.count,
            protectedValue: active.reduce(0) { $0 + $1.cost },
            expiringSoonCount: active.filter { $0.daysUntilExpiration(from: now, calendar: calendar) <= warrantyExpiringWindowDays }.count,
            expiredCount: warranties.count - active.count
        )
    }
}
