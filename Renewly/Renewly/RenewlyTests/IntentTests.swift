//
// IntentTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@Suite("Siri answers")
struct IntentSummariesTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 12)) ?? .distantPast
    }

    private func item(
        _ title: String, _ category: ItemCategory = .subscription, in days: Int,
        cost: Double = 10, currency: String = "USD", cycle: BillingCycle = .monthly, trial: Bool = false
    ) -> ItemSnapshot {
        let date = calendar.date(byAdding: .day, value: days, to: now) ?? now
        return ItemSnapshot(
            id: UUID(), title: title, category: category, cost: cost, currencyCode: currency,
            expirationDate: date, billingCycle: cycle, isNotificationEnabled: false,
            trialEndDate: trial ? date : nil
        )
    }

    @Test("Each kind of item gets natural wording")
    func phrases() {
        #expect(IntentSummaries.phrase(for: item("Netflix", in: 1), now: now, calendar: calendar) == "Netflix renews tomorrow")
        #expect(IntentSummaries.phrase(for: item("YouTube Premium", in: 3, trial: true), now: now, calendar: calendar)
            == "YouTube Premium's trial ends in 3 days")
        #expect(IntentSummaries.phrase(for: item("AirPods Pro", .warranty, in: 0), now: now, calendar: calendar)
            == "AirPods Pro warranty expires today")
    }

    @Test("Upcoming lists only the window, soonest first")
    func upcomingWindow() {
        let items = [item("Later", in: 20), item("Spotify", in: 5), item("Hulu", in: -1), item("Netflix", in: 0)]
        let due = IntentSummaries.upcoming(items, within: 7, now: now, calendar: calendar)
        #expect(due.map(\.title) == ["Netflix", "Spotify"])
    }

    @Test func upcomingDialog() {
        let dialog = IntentSummaries.upcomingDialog(
            [item("Netflix", in: 1), item("AirPods Pro", .warranty, in: 3)], within: 7, now: now, calendar: calendar
        )
        #expect(dialog == "2 things in the next 7 days: Netflix renews tomorrow and AirPods Pro warranty expires in 3 days.")
    }

    @Test("Long lists are summarised")
    func longListSummarised() {
        let items = (1...6).map { item("Service \($0)", in: $0) }
        let dialog = IntentSummaries.upcomingDialog(items, within: 7, now: now, calendar: calendar)
        #expect(dialog.hasPrefix("6 things in the next 7 days:"))
        #expect(dialog.hasSuffix("and 2 more."))
        #expect(!dialog.contains("Service 5"))
    }

    @Test func nothingDue() {
        #expect(IntentSummaries.upcomingDialog([item("Netflix", in: 30)], within: 7, now: now, calendar: calendar)
            == "Nothing renews or expires in the next 7 days.")
        #expect(IntentSummaries.upcomingDialog([], within: 1, now: now, calendar: calendar)
            == "Nothing renews or expires today or tomorrow.")
    }

    @Test("Spend adds up monthly cost in the primary currency")
    func spend() {
        let items = [
            item("Netflix", in: 3, cost: 15),
            item("iCloud+", in: 40, cost: 120, cycle: .yearly),
            item("Deezer", in: 9, cost: 11, currency: "EUR"),
            item("AirPods", .warranty, in: 90, cost: 249)
        ]
        let dialog = IntentSummaries.spendDialog(items, currencyCode: "USD", now: now, calendar: calendar)
        let amount = 25.0.formatted(.currency(code: "USD"))
        #expect(dialog == "You spend about \(amount) a month on 2 subscriptions. Items in other currencies aren't included.")
    }

    @Test func spendWithNothingTracked() {
        #expect(IntentSummaries.spendDialog([], currencyCode: "USD", now: now, calendar: calendar)
            == "You aren't tracking any subscriptions yet.")
        #expect(IntentSummaries.spendDialog([item("Deezer", in: 3, currency: "EUR")], currencyCode: "USD", now: now, calendar: calendar)
            == "You have no subscriptions in USD. Items in other currencies aren't added up.")
    }

    @Test("Entities describe the item for Siri and Shortcuts")
    func entitySubtitle() {
        let entity = ItemEntity(item("Netflix", in: 2), now: now, calendar: calendar)
        #expect(entity.title == "Netflix")
        #expect(entity.subtitle == "Subscription · Renews in 2 days")
        #expect(ItemEntity(item("Hulu", in: -3), now: now, calendar: calendar).subtitle == "Subscription · Expired")
    }
}

@MainActor
@Suite("Siri navigation")
struct IntentNavigationTests {
    @Test("Add-item requests wait until consumed, once")
    func newItemRequest() {
        let router = NotificationRouter()
        router.requestNewItem(.warranty)
        #expect(router.pendingNewItem == .warranty)
        #expect(router.consumeNewItemRequest() == .warranty)
        #expect(router.consumeNewItemRequest() == nil)
    }

    @Test("The editor can start as a warranty with a one-year suggestion")
    func editorStartsAsWarranty() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 12)) ?? .distantPast
        let viewModel = ItemEditorViewModel(
            item: nil, category: .warranty, defaultCurrency: "USD",
            dependencies: PreviewData.dependencies(), now: now, calendar: calendar
        )
        #expect(viewModel.category == .warranty)
        #expect(calendar.dateComponents([.year, .month, .day], from: viewModel.expirationDate)
            == DateComponents(year: 2027, month: 3, day: 1))
    }
}
