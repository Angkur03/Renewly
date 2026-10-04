//
// DashboardViewModel.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation
import SwiftData

nonisolated enum DashboardFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case subscriptions
    case warranties
    case expiringSoon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .subscriptions: "Subscriptions"
        case .warranties: "Warranties"
        case .expiringSoon: "Expiring Soon"
        }
    }

    func matches(_ item: ItemSnapshot, now: Date, calendar: Calendar = .current) -> Bool {
        switch self {
        case .all: true
        case .subscriptions: item.category == .subscription
        case .warranties: item.category == .warranty
        case .expiringSoon: item.isExpiringSoon(now: now, calendar: calendar)
        }
    }
}

nonisolated struct DashboardSummary: Equatable, Sendable {
    nonisolated struct NextUp: Equatable, Sendable {
        let title: String
        let category: ItemCategory
        let daysLeft: Int
    }

    let currencyCode: String
    let monthlyBurn: Double
    let protectedCapital: Double
    let subscriptionCount: Int
    let activeWarrantyCount: Int
    /// Items in other currencies, left out of the totals because there is no exchange-rate source.
    let excludedItemCount: Int
    /// The soonest upcoming subscription renewal, across all currencies.
    var nextRenewal: NextUp? = nil
    /// The soonest warranty that has not expired yet, across all currencies.
    var nextWarranty: NextUp? = nil

    static func make(
        from items: [ItemSnapshot],
        currencyCode: String,
        now: Date,
        calendar: Calendar = .current
    ) -> DashboardSummary {
        let matching = items.filter { $0.currencyCode == currencyCode }
        let subscriptions = matching.filter { $0.category == .subscription }
        let activeWarranties = matching.filter {
            $0.category == .warranty && !$0.isExpired(now: now, calendar: calendar)
        }
        let upcoming = items.filter { !$0.isExpired(now: now, calendar: calendar) }
        func soonest(_ category: ItemCategory) -> NextUp? {
            upcoming
                .filter { $0.category == category }
                .min { $0.expirationDate < $1.expirationDate }
                .map { NextUp(title: $0.title, category: category, daysLeft: $0.daysUntilExpiration(from: now, calendar: calendar)) }
        }
        return DashboardSummary(
            currencyCode: currencyCode,
            monthlyBurn: subscriptions.reduce(0) { $0 + $1.monthlyCost },
            protectedCapital: activeWarranties.reduce(0) { $0 + $1.cost },
            subscriptionCount: subscriptions.count,
            activeWarrantyCount: activeWarranties.count,
            excludedItemCount: items.count - matching.count,
            nextRenewal: soonest(.subscription),
            nextWarranty: soonest(.warranty)
        )
    }
}

nonisolated struct DashboardSections<Item> {
    /// Soonest first.
    let upcoming: [Item]
    /// Most recently expired first.
    let expired: [Item]

    var isEmpty: Bool { upcoming.isEmpty && expired.isEmpty }
}

@Observable
@MainActor
final class DashboardViewModel {
    var filter: DashboardFilter = .all
    var errorMessage: String?
    private(set) var interactionCount = 0

    @ObservationIgnored private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func sections(from items: [TrackedItem], query: String, now: Date = .now) -> DashboardSections<TrackedItem> {
        let matching = items.filter { filter.matches($0.snapshot, now: now) && Self.matchesSearch($0, query: query) }
        let (expired, upcoming) = matching.reduce(into: ([TrackedItem](), [TrackedItem]())) { result, item in
            if item.snapshot.isExpired(now: now) {
                result.0.append(item)
            } else {
                result.1.append(item)
            }
        }
        return DashboardSections(
            upcoming: upcoming.sorted { $0.expirationDate < $1.expirationDate },
            expired: expired.sorted { $0.expirationDate > $1.expirationDate }
        )
    }

    func counts(for items: [TrackedItem], now: Date = .now) -> [DashboardFilter: Int] {
        let snapshots = items.map(\.snapshot)
        return Dictionary(uniqueKeysWithValues: DashboardFilter.allCases.map { filter in
            (filter, snapshots.filter { filter.matches($0, now: now) }.count)
        })
    }

    static func matchesSearch(_ item: TrackedItem, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return [item.title, item.retailer, item.serialNumber, item.category.title]
            .compactMap { $0 }
            .contains { $0.localizedStandardContains(trimmed) }
    }

    func summary(for items: [TrackedItem], currencyCode: String, now: Date = .now) -> DashboardSummary {
        DashboardSummary.make(from: items.map(\.snapshot), currencyCode: currencyCode, now: now)
    }

    func registerInteraction() {
        interactionCount += 1
    }

    func delete(_ item: TrackedItem, in context: ModelContext) async {
        guard await ItemDeletionService(dependencies: dependencies).delete(item, in: context) else {
            errorMessage = "The item could not be deleted. Please try again."
            return
        }
        registerInteraction()
    }
}
