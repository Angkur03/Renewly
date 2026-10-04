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
}
#endif
