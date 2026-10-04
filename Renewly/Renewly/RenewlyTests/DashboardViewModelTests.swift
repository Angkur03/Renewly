//
// DashboardViewModelTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@Suite("Dashboard filtering and totals")
struct DashboardViewModelTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 8)) ?? .distantPast
    }

    private func item(
        _ category: ItemCategory,
        cost: Double,
        currency: String = "USD",
        cycle: BillingCycle = .monthly,
        daysUntilExpiration: Int
    ) -> ItemSnapshot {
        ItemSnapshot(
            id: UUID(),
            title: "Item",
            category: category,
            cost: cost,
            currencyCode: currency,
            expirationDate: calendar.date(byAdding: .day, value: daysUntilExpiration, to: now) ?? now,
            billingCycle: cycle,
            isNotificationEnabled: false
        )
    }

    @Test("Monthly burn normalizes quarterly and yearly cycles")
    func monthlyBurnNormalizesCycles() {
        let items = [
            item(.subscription, cost: 10, cycle: .monthly, daysUntilExpiration: 20),
            item(.subscription, cost: 30, cycle: .quarterly, daysUntilExpiration: 40),
            item(.subscription, cost: 120, cycle: .yearly, daysUntilExpiration: 200)
        ]
        let summary = DashboardSummary.make(from: items, currencyCode: "USD", now: now, calendar: calendar)
        #expect(summary.monthlyBurn == 30)
        #expect(summary.subscriptionCount == 3)
    }

    @Test("Protected capital counts only unexpired warranties")
    func protectedCapitalIgnoresExpiredWarranties() {
        let items = [
            item(.warranty, cost: 1000, daysUntilExpiration: 365),
            item(.warranty, cost: 250, daysUntilExpiration: 0),
            item(.warranty, cost: 500, daysUntilExpiration: -1)
        ]
        let summary = DashboardSummary.make(from: items, currencyCode: "USD", now: now, calendar: calendar)
        #expect(summary.protectedCapital == 1250)
        #expect(summary.activeWarrantyCount == 2)
        #expect(summary.monthlyBurn == 0)
    }

    @Test("Totals include only the main currency and report excluded items")
    func totalsRespectPrimaryCurrency() {
        let items = [
            item(.subscription, cost: 12, currency: "USD", daysUntilExpiration: 10),
            item(.subscription, cost: 99, currency: "EUR", daysUntilExpiration: 10),
            item(.warranty, cost: 800, currency: "EUR", daysUntilExpiration: 100)
        ]
        let summary = DashboardSummary.make(from: items, currencyCode: "USD", now: now, calendar: calendar)
        #expect(summary.monthlyBurn == 12)
        #expect(summary.protectedCapital == 0)
        #expect(summary.excludedItemCount == 2)
        #expect(summary.currencyCode == "USD")
    }

    @Test("Category filters match their own category")
    func categoryFilters() {
        let subscription = item(.subscription, cost: 5, daysUntilExpiration: 30)
        let warranty = item(.warranty, cost: 5, daysUntilExpiration: 30)

        #expect(DashboardFilter.all.matches(subscription, now: now, calendar: calendar))
        #expect(DashboardFilter.all.matches(warranty, now: now, calendar: calendar))
        #expect(DashboardFilter.subscriptions.matches(subscription, now: now, calendar: calendar))
        #expect(!DashboardFilter.subscriptions.matches(warranty, now: now, calendar: calendar))
        #expect(DashboardFilter.warranties.matches(warranty, now: now, calendar: calendar))
        #expect(!DashboardFilter.warranties.matches(subscription, now: now, calendar: calendar))
    }

    @Test("Expiring Soon covers today through 13 days, excluding expired items", arguments: [
        (0, true), (1, true), (13, true), (14, false), (30, false), (-1, false)
    ])
    func expiringSoonBoundaries(days: Int, expected: Bool) {
        let snapshot = item(.warranty, cost: 1, daysUntilExpiration: days)
        #expect(DashboardFilter.expiringSoon.matches(snapshot, now: now, calendar: calendar) == expected)
    }

    @Test("Billing cycle monthly equivalents")
    func billingCycleMonthlyEquivalent() {
        #expect(BillingCycle.monthly.monthlyEquivalent(of: 9) == 9)
        #expect(BillingCycle.quarterly.monthlyEquivalent(of: 9) == 3)
        #expect(BillingCycle.yearly.monthlyEquivalent(of: 120) == 10)
    }
}
