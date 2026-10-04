//
// DashboardViewModel.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation
import OSLog
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
    let currencyCode: String
    let monthlyBurn: Double
    let protectedCapital: Double
    let subscriptionCount: Int
    let activeWarrantyCount: Int
    /// Items in other currencies, left out of the totals because there is no exchange-rate source.
    let excludedItemCount: Int

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
        return DashboardSummary(
            currencyCode: currencyCode,
            monthlyBurn: subscriptions.reduce(0) { $0 + $1.monthlyCost },
            protectedCapital: activeWarranties.reduce(0) { $0 + $1.cost },
            subscriptionCount: subscriptions.count,
            activeWarrantyCount: activeWarranties.count,
            excludedItemCount: items.count - matching.count
        )
    }
}

@Observable
@MainActor
final class DashboardViewModel {
    var filter: DashboardFilter = .all
    var errorMessage: String?
    private(set) var interactionCount = 0

    @ObservationIgnored private let dependencies: AppDependencies
    @ObservationIgnored private let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly", category: "Dashboard")

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func visibleItems(from items: [TrackedItem], now: Date = .now) -> [TrackedItem] {
        items.filter { filter.matches($0.snapshot, now: now) }
    }

    func summary(for items: [TrackedItem], currencyCode: String, now: Date = .now) -> DashboardSummary {
        DashboardSummary.make(from: items.map(\.snapshot), currencyCode: currencyCode, now: now)
    }

    func registerInteraction() {
        interactionCount += 1
    }

    func delete(_ item: TrackedItem, in context: ModelContext) async {
        let itemID = item.id
        let receiptPath = item.receiptImagePath

        context.delete(item)
        do {
            try context.save()
        } catch {
            context.rollback()
            errorMessage = "The item could not be deleted. Please try again."
            return
        }
        registerInteraction()

        await dependencies.notifications.cancel(for: itemID)
        guard let receiptPath else { return }
        do {
            try await dependencies.receipts.delete(relativePath: receiptPath)
        } catch {
            logger.error("Orphaned receipt image could not be removed: \(error.userMessage, privacy: .public)")
        }
    }
}
