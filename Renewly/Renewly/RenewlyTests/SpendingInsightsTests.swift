//
// SpendingInsightsTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@Suite("Spending insights")
struct SpendingInsightsTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    /// Mid-month so the projection's first bucket is a partial month.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 9)) ?? .distantPast
    }

    private func snapshot(
        _ title: String,
        _ category: ItemCategory = .subscription,
        cost: Double,
        cycle: BillingCycle = .monthly,
        currency: String = "USD",
        inDays days: Int
    ) -> ItemSnapshot {
        ItemSnapshot(
            id: UUID(),
            title: title,
            category: category,
            cost: cost,
            currencyCode: currency,
            expirationDate: calendar.date(byAdding: .day, value: days, to: now) ?? now,
            billingCycle: cycle,
            isNotificationEnabled: false
        )
    }

    private func make(_ items: [ItemSnapshot]) -> SpendingInsights {
        SpendingInsights.make(from: items, currencyCode: "USD", now: now, calendar: calendar)
    }

    @Test("Monthly and yearly totals normalise every billing cycle")
    func totals() {
        let insights = make([
            snapshot("A", cost: 10, inDays: 5),
            snapshot("B", cost: 30, cycle: .quarterly, inDays: 40),
            snapshot("C", cost: 120, cycle: .yearly, inDays: 200)
        ])
        #expect(insights.monthlyTotal == 30)
        #expect(insights.yearlyTotal == 360)
        #expect(insights.subscriptionCount == 3)
    }

    @Test("Twelve-month projection adds up to one year of charges")
    func projectionMatchesYear() {
        let insights = make([
            snapshot("Monthly", cost: 10, inDays: 3),
            snapshot("Quarterly", cost: 30, cycle: .quarterly, inDays: 15),
            snapshot("Yearly", cost: 120, cycle: .yearly, inDays: 100)
        ])
        #expect(insights.projection.count == SpendingInsights.projectionMonths)
        #expect(insights.projectionTotal == 120 + 120 + 120)
        // June holds a monthly, a quarterly and the yearly charge.
        #expect(insights.peakMonth?.amount == 160)
        #expect(insights.peakMonth.map { calendar.component(.month, from: $0.month) } == 6)
    }

    @Test("The projection starts with the current month")
    func projectionStartsThisMonth() {
        let insights = make([snapshot("Monthly", cost: 10, inDays: 3)])
        let first = insights.projection.first
        #expect(first.map { calendar.component(.month, from: $0.month) } == 3)
        #expect(first?.amount == 10)
    }

    @Test("Upcoming charges cover 30 days and include repeat renewals")
    func upcomingWindow() {
        let insights = make([
            snapshot("Soon", cost: 5, inDays: 0),
            snapshot("Edge", cost: 7, inDays: 30),
            snapshot("Later", cost: 9, inDays: 31)
        ])
        #expect(insights.upcomingCharges.map(\.title) == ["Soon", "Edge"])
        #expect(insights.upcomingTotal == 12)
    }

    @Test("A lapsed subscription is projected from its next renewal, never in the past")
    func lapsedSubscription() {
        let insights = make([snapshot("Lapsed", cost: 10, inDays: -45)])
        let today = calendar.startOfDay(for: now)
        #expect(insights.upcomingCharges.allSatisfy { $0.date >= today })
        #expect(insights.projectionTotal == 120)
    }

    @Test("Breakdown keeps the four biggest and groups the rest into Other")
    func sharesGroupOther() {
        let items = (1...7).map { snapshot("S\($0)", cost: Double($0 * 10), inDays: 10) }
        let shares = make(items).shares
        #expect(shares.count == SpendingInsights.maxShareSlices)
        #expect(shares.prefix(4).map(\.title) == ["S7", "S6", "S5", "S4"])
        #expect(shares.last?.isOther == true)
        #expect(shares.last?.monthlyAmount == 60)
        #expect(abs(shares.reduce(0) { $0 + $1.fraction } - 1) < 0.0001)
    }

    @Test("Five or fewer subscriptions are listed individually")
    func sharesWithoutOther() {
        let shares = make((1...5).map { snapshot("S\($0)", cost: 10, inDays: 10) }).shares
        #expect(shares.count == 5)
        #expect(!shares.contains { $0.isOther })
    }

    @Test("Free subscriptions do not divide by zero")
    func freeSubscriptions() {
        let insights = make([snapshot("Free", cost: 0, inDays: 4)])
        #expect(insights.shares.isEmpty)
        #expect(insights.monthlyTotal == 0)
    }

    @Test("Warranty coverage splits active, ending soon and expired")
    func warrantyCoverage() {
        let coverage = make([
            snapshot("Laptop", .warranty, cost: 2000, inDays: 400),
            snapshot("Phone", .warranty, cost: 800, inDays: 60),
            snapshot("TV", .warranty, cost: 1200, inDays: -5)
        ]).warranties
        #expect(coverage.activeCount == 2)
        #expect(coverage.protectedValue == 2800)
        #expect(coverage.expiringSoonCount == 1)
        #expect(coverage.expiredCount == 1)
    }

    @Test("Other currencies are excluded and counted")
    func otherCurrencies() {
        let insights = make([
            snapshot("USD", cost: 10, inDays: 5),
            snapshot("EUR", cost: 99, currency: "EUR", inDays: 5)
        ])
        #expect(insights.monthlyTotal == 10)
        #expect(insights.excludedItemCount == 1)
        #expect(!insights.isEmpty)
        #expect(make([snapshot("EUR", cost: 99, currency: "EUR", inDays: 5)]).isEmpty)
    }

    @Test("Month-end renewals stay on the last day of each month")
    func monthEndRenewals() {
        let jan31 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 9)) ?? now
        let item = ItemSnapshot(
            id: UUID(), title: "End", category: .subscription, cost: 1, currencyCode: "USD",
            expirationDate: jan31, billingCycle: .monthly, isNotificationEnabled: false
        )
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? now
        let end = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1)) ?? now
        let days = SpendingInsights.renewals(of: item, from: start, before: end, calendar: calendar)
            .map { calendar.component(.day, from: $0.date) }
        #expect(days == [31, 28, 31, 30])
    }
}
