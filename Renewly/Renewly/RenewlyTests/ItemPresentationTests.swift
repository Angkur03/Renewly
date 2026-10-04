//
// ItemPresentationTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import SwiftData
import Testing
@testable import Renewly

@Suite("Expiry wording")
struct ExpiryTextTests {
    @Test("Relative phrases", arguments: [
        (-5, ItemCategory.warranty, "Expired 5 days ago"),
        (-1, .warranty, "Expired yesterday"),
        (0, .warranty, "Expires today"),
        (1, .subscription, "Renews tomorrow"),
        (9, .subscription, "Renews in 9 days"),
        (-2, .subscription, "Ended 2 days ago")
    ])
    func relative(days: Int, category: ItemCategory, expected: String) {
        #expect(ExpiryText.relative(days: days, category: category) == expected)
    }

    @Test("Badges", arguments: [(-1, "Expired"), (0, "Today"), (1, "Tomorrow"), (6, "6d left")])
    func badge(days: Int, expected: String) {
        #expect(ExpiryText.badge(days: days) == expected)
    }

    @Test("Pluralisation")
    func pluralisation() {
        #expect(ExpiryText.count(1, "subscription") == "1 subscription")
        #expect(ExpiryText.count(0, "subscription") == "0 subscriptions")
        #expect(ExpiryText.count(2, "active warranty", plural: "active warranties") == "2 active warranties")
    }
}

@Suite("Time-left progress")
struct TimeLeftProgressTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 10)) ?? .distantPast
    }

    @Test("Subscriptions measure the current billing period, not the original start")
    func subscriptionUsesBillingPeriod() {
        let progress = TimeLeftProgress.make(
            category: .subscription, billingCycle: .monthly,
            startDate: date(2020, 1, 1), expirationDate: date(2026, 5, 1),
            now: date(2026, 4, 16), calendar: calendar
        )
        #expect(progress.totalDays == 30)
        #expect(progress.daysLeft == 15)
        #expect(abs(progress.elapsedFraction - 0.5) < 0.0001)
    }

    @Test("Warranties measure purchase to expiry and clamp outside the window")
    func warrantyClamps() {
        let expired = TimeLeftProgress.make(
            category: .warranty, billingCycle: .monthly,
            startDate: date(2024, 1, 1), expirationDate: date(2025, 1, 1),
            now: date(2026, 1, 1), calendar: calendar
        )
        #expect(expired.elapsedFraction == 1)
        #expect(expired.daysLeft < 0)

        let notStarted = TimeLeftProgress.make(
            category: .warranty, billingCycle: .monthly,
            startDate: date(2027, 1, 1), expirationDate: date(2028, 1, 1),
            now: date(2026, 1, 1), calendar: calendar
        )
        #expect(notStarted.elapsedFraction == 0)
    }

    @Test("Zero-length windows do not divide by zero")
    func zeroLength() {
        let sameDay = TimeLeftProgress.make(
            category: .warranty, billingCycle: .monthly,
            startDate: date(2026, 3, 3), expirationDate: date(2026, 3, 3),
            now: date(2026, 3, 3), calendar: calendar
        )
        #expect(sameDay.totalDays == 0)
        #expect(sameDay.elapsedFraction == 1)
    }
}

@MainActor
@Suite("Dashboard sections and search")
struct DashboardSectionsTests {
    private let context: ModelContext
    private let items: [TrackedItem]

    init() throws {
        let container = try ModelContainer(for: TrackedItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
        let day: TimeInterval = 86_400
        items = [
            TrackedItem(title: "Netflix", category: .subscription, cost: 15, currencyCode: "USD",
                        startDate: .now, expirationDate: .now.addingTimeInterval(day * 20)),
            TrackedItem(title: "MacBook Pro", category: .warranty, cost: 2000, currencyCode: "USD",
                        startDate: .now, expirationDate: .now.addingTimeInterval(day * 5),
                        serialNumber: "C02XYZ", retailer: "Apple Store"),
            TrackedItem(title: "Old Phone", category: .warranty, cost: 400, currencyCode: "USD",
                        startDate: .now, expirationDate: .now.addingTimeInterval(-day * 3)),
            TrackedItem(title: "Older TV", category: .warranty, cost: 900, currencyCode: "USD",
                        startDate: .now, expirationDate: .now.addingTimeInterval(-day * 40))
        ]
        items.forEach(context.insert)
    }

    private var viewModel: DashboardViewModel {
        DashboardViewModel(dependencies: PreviewData.dependencies())
    }

    @Test("Upcoming is soonest first, expired is most recent first")
    func ordering() {
        let sections = viewModel.sections(from: items.shuffled(), query: "")
        #expect(sections.upcoming.map(\.title) == ["MacBook Pro", "Netflix"])
        #expect(sections.expired.map(\.title) == ["Old Phone", "Older TV"])
    }

    @Test("Search matches title, retailer, serial and type, ignoring case and whitespace", arguments: [
        ("netflix", ["Netflix"]),
        ("  apple store ", ["MacBook Pro"]),
        ("c02x", ["MacBook Pro"]),
        ("warranty", ["MacBook Pro", "Old Phone", "Older TV"]),
        ("zzz", [String]())
    ])
    func search(query: String, expected: [String]) {
        let sections = viewModel.sections(from: items, query: query)
        #expect((sections.upcoming + sections.expired).map(\.title).sorted() == expected.sorted())
    }

    @Test("Filter counts")
    func counts() {
        let counts = viewModel.counts(for: items)
        #expect(counts[.all] == 4)
        #expect(counts[.subscriptions] == 1)
        #expect(counts[.warranties] == 3)
        #expect(counts[.expiringSoon] == 1)
    }

    @Test("Next up shows the soonest renewal and the soonest unexpired warranty separately")
    func nextUp() {
        let summary = DashboardSummary.make(from: items.map(\.snapshot), currencyCode: "USD", now: .now)
        #expect(summary.nextRenewal?.title == "Netflix")
        #expect(summary.nextRenewal?.daysLeft == 20)
        #expect(summary.nextWarranty?.title == "MacBook Pro")
        #expect(summary.nextWarranty?.daysLeft == 5)
    }

    @Test("A category with nothing upcoming has no next-up row")
    func nextUpWithoutUpcomingWarranty() {
        let subscriptionsAndExpired = items.filter { $0.title != "MacBook Pro" }.map(\.snapshot)
        let summary = DashboardSummary.make(from: subscriptionsAndExpired, currencyCode: "USD", now: .now)
        #expect(summary.nextRenewal?.title == "Netflix")
        #expect(summary.nextWarranty == nil)
    }
}
