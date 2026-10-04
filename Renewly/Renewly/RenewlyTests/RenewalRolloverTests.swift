//
// RenewalRolloverTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import SwiftData
import Testing
@testable import Renewly

@MainActor
@Suite("Renewal rollover")
struct RenewalRolloverTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
    }

    private func day(of date: Date) -> DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }

    @Test("Month-end anchors clamp to short months without drifting")
    func monthEndDoesNotDrift() {
        let anchor = date(2026, 1, 31)
        #expect(day(of: BillingCycle.monthly.nextRenewal(from: anchor, onOrAfter: date(2026, 2, 10), calendar: calendar))
                == DateComponents(year: 2026, month: 2, day: 28))
        #expect(day(of: BillingCycle.monthly.nextRenewal(from: anchor, onOrAfter: date(2026, 3, 1), calendar: calendar))
                == DateComponents(year: 2026, month: 3, day: 31))
        #expect(day(of: BillingCycle.monthly.nextRenewal(from: date(2027, 1, 31), onOrAfter: date(2028, 2, 2), calendar: calendar))
                == DateComponents(year: 2028, month: 2, day: 29))
    }

    @Test("Quarterly and yearly cycles step by their length")
    func longerCycles() {
        #expect(day(of: BillingCycle.quarterly.nextRenewal(from: date(2026, 1, 15), onOrAfter: date(2026, 5, 1), calendar: calendar))
                == DateComponents(year: 2026, month: 7, day: 15))
        #expect(day(of: BillingCycle.yearly.nextRenewal(from: date(2022, 6, 1), onOrAfter: date(2026, 6, 2), calendar: calendar))
                == DateComponents(year: 2027, month: 6, day: 1))
    }

    @Test("Today and future dates are left unchanged")
    func todayAndFutureUnchanged() {
        let today = date(2026, 4, 10, hour: 18)
        let sameDay = date(2026, 4, 10, hour: 9)
        let future = date(2026, 9, 1)
        #expect(BillingCycle.monthly.nextRenewal(from: sameDay, onOrAfter: today, calendar: calendar) == sameDay)
        #expect(BillingCycle.monthly.nextRenewal(from: future, onOrAfter: today, calendar: calendar) == future)
    }

    @Test("A renewal landing exactly today counts as the next one")
    func landsOnToday() {
        let result = BillingCycle.monthly.nextRenewal(from: date(2026, 2, 10), onOrAfter: date(2026, 4, 10, hour: 20), calendar: calendar)
        #expect(day(of: result) == DateComponents(year: 2026, month: 4, day: 10))
    }

    @Test("Period start steps back one cycle")
    func periodStart() {
        #expect(day(of: BillingCycle.quarterly.periodStart(endingAt: date(2026, 7, 15), calendar: calendar))
                == DateComponents(year: 2026, month: 4, day: 15))
    }

    @Test("Service rolls only past subscriptions and persists the new date")
    func serviceRollsPastSubscriptions() throws {
        let container = try ModelContainer(for: TrackedItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let now = date(2026, 5, 20)

        let lapsed = TrackedItem(
            title: "Lapsed", category: .subscription, cost: 5, currencyCode: "USD",
            startDate: date(2026, 1, 3), expirationDate: date(2026, 4, 3)
        )
        let current = TrackedItem(
            title: "Current", category: .subscription, cost: 5, currencyCode: "USD",
            startDate: date(2026, 5, 1), expirationDate: date(2026, 6, 1)
        )
        let expiredWarranty = TrackedItem(
            title: "Warranty", category: .warranty, cost: 500, currencyCode: "USD",
            startDate: date(2024, 1, 1), expirationDate: date(2025, 1, 1)
        )
        [lapsed, current, expiredWarranty].forEach(context.insert)
        try context.save()

        let rolled = RenewalRolloverService(calendar: calendar).rollForward(in: context, now: now)

        #expect(rolled == 1)
        #expect(day(of: lapsed.expirationDate) == DateComponents(year: 2026, month: 6, day: 3))
        #expect(day(of: current.expirationDate) == DateComponents(year: 2026, month: 6, day: 1))
        #expect(day(of: expiredWarranty.expirationDate) == DateComponents(year: 2025, month: 1, day: 1))
        #expect(!context.hasChanges)
    }

    @Test("Running the service twice is a no-op the second time")
    func serviceIsIdempotent() throws {
        let container = try ModelContainer(for: TrackedItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        context.insert(TrackedItem(
            title: "Yearly", category: .subscription, cost: 50, currencyCode: "USD",
            startDate: date(2020, 2, 1), expirationDate: date(2021, 2, 1), billingCycle: .yearly
        ))
        try context.save()

        let service = RenewalRolloverService(calendar: calendar)
        #expect(service.rollForward(in: context, now: date(2026, 3, 1)) == 1)
        #expect(service.rollForward(in: context, now: date(2026, 3, 1)) == 0)
    }
}
