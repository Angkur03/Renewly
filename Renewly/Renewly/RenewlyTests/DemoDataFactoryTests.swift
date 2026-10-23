//
// DemoDataFactoryTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

#if DEBUG
import Foundation
import Testing
@testable import Renewly

@MainActor
@Suite("DemoDataFactory")
struct DemoDataFactoryTests {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    @Test("Every scenario produces items with reminders off", arguments: DemoScenario.allCases)
    func scenarioProducesItems(scenario: DemoScenario) {
        let snapshots = DemoDataFactory.items(for: scenario, currency: "USD", now: now).map(\.snapshot)
        #expect(!snapshots.isEmpty)
        #expect(snapshots.allSatisfy { !$0.isNotificationEnabled })
        #expect(Set(snapshots.map(\.id)).count == snapshots.count)
    }

    @Test("Expiring soon scenario only contains items due within the threshold")
    func expiringSoonScenario() {
        let snapshots = DemoDataFactory.items(for: .expiringSoon, currency: "USD", now: now).map(\.snapshot)
        #expect(snapshots.allSatisfy { $0.isExpiringSoon(now: now) })
    }

    @Test("Expired scenario only contains expired items")
    func expiredScenario() {
        let snapshots = DemoDataFactory.items(for: .expired, currency: "USD", now: now).map(\.snapshot)
        #expect(snapshots.allSatisfy { $0.isExpired(now: now) })
    }

    @Test("Mixed currencies scenario avoids the main currency so totals show exclusions")
    func mixedCurrenciesScenario() {
        let snapshots = DemoDataFactory.items(for: .mixedCurrencies, currency: "USD", now: now).map(\.snapshot)
        #expect(!snapshots.contains { $0.currencyCode == "USD" })
        let summary = DashboardSummary.make(from: snapshots, currencyCode: "USD", now: now)
        #expect(summary.excludedItemCount == snapshots.count)
    }

    @Test("Starter and bulk scenarios use the main currency")
    func scenariosUseMainCurrency() {
        let starter = DemoDataFactory.items(for: .starter, currency: "BDT", now: now)
        let bulk = DemoDataFactory.items(for: .bulk, currency: "BDT", now: now)
        #expect(starter.allSatisfy { $0.currencyCode == "BDT" })
        #expect(bulk.count == DemoScenario.bulkCount)
        #expect(bulk.allSatisfy { $0.currencyCode == "BDT" })
    }

    @Test("Demo prices look local in other currencies", arguments: [
        (22.99, "USD", 22.99),
        (22.99, "EUR", 22.99),
        (22.99, "JPY", 1950.0),
        (13.99, "BRL", 36.99),
        (2499.0, "BRL", 6500.0),
    ])
    func localPrices(usd: Double, currency: String, expected: Double) {
        #expect(abs(DemoDataFactory.localPrice(usd, currency: currency) - expected) < 0.001)
    }

    @Test("Demo reminders stay within the free limit and cover the soonest item of each category")
    func demoReminders() {
        let items = DemoDataFactory.items(for: .starter, currency: "USD", now: now)
            + DemoDataFactory.items(for: .expired, currency: "USD", now: now)
        DemoDataFactory.enableFreeReminders(on: items, now: now)

        let enabled = items.filter(\.isNotificationEnabled)
        #expect(enabled.count == NotificationManager.freeAlertLimit)
        #expect(enabled.allSatisfy { $0.expirationDate >= now })
        #expect(Set(enabled.map(\.title)) == ["YouTube Premium", "LG C3 OLED 65\"", "Spotify Duo"])
    }

    @Test("Sample plans use local prices with a one-week trial")
    func demoPlans() {
        let yen = ProPlan.demoPlans(currencyCode: "JPY", locale: Locale(identifier: "ja_JP"))
        #expect(yen.map(\.price) == [600, 2400])
        #expect(yen.allSatisfy { $0.freeTrialDays == 7 })

        let taka = ProPlan.demoPlans(currencyCode: "BDT", locale: Locale(identifier: "en_US"))
        #expect(taka.map(\.displayPrice) == ["$4.99", "$19.99"])
    }
}
#endif
