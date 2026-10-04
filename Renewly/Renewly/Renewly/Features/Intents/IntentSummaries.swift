//
// IntentSummaries.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// The sentences Siri speaks. Kept free of App Intents types so they can be unit tested.
nonisolated enum IntentSummaries {
    /// How many items Siri reads out before summarising the rest as "and N more".
    static let spokenItemLimit = 4

    /// Items renewing or expiring from today through `days` days from now, soonest first.
    static func upcoming(_ items: [ItemSnapshot], within days: Int, now: Date, calendar: Calendar = .current) -> [ItemSnapshot] {
        items
            .filter { (0...days).contains($0.daysUntilExpiration(from: now, calendar: calendar)) }
            .sorted { ($0.expirationDate, $0.title) < ($1.expirationDate, $1.title) }
    }

    static func upcomingDialog(_ items: [ItemSnapshot], within days: Int, now: Date, calendar: Calendar = .current) -> String {
        let window = days == 1 ? "today or tomorrow" : "in the next \(days) days"
        let due = upcoming(items, within: days, now: now, calendar: calendar)
        guard !due.isEmpty else {
            return "Nothing renews or expires \(window)."
        }
        var phrases = due.prefix(spokenItemLimit).map { phrase(for: $0, now: now, calendar: calendar) }
        if due.count > spokenItemLimit {
            phrases.append("\(due.count - spokenItemLimit) more")
        }
        let count = due.count == 1 ? "One thing" : "\(due.count) things"
        return "\(count) \(window): \(phrases.formatted(.list(type: .and)))."
    }

    /// e.g. "Netflix renews tomorrow", "YouTube Premium's trial ends in 3 days", "AirPods Pro warranty expires today".
    static func phrase(for item: ItemSnapshot, now: Date, calendar: Calendar = .current) -> String {
        let days = max(0, item.daysUntilExpiration(from: now, calendar: calendar))
        let kind = WidgetSnapshotBuilder.kind(of: item, calendar: calendar)
        let timing = WidgetText.relative(days: days, kind: kind)
        let lowered = timing.prefix(1).lowercased() + timing.dropFirst()
        switch kind {
        case .subscription: return "\(item.title) \(lowered)"
        case .trial: return "\(item.title)'s \(lowered)"
        case .warranty: return "\(item.title) warranty \(lowered)"
        }
    }

    static func spendDialog(_ items: [ItemSnapshot], currencyCode: String, now: Date, calendar: Calendar = .current) -> String {
        let summary = DashboardSummary.make(from: items, currencyCode: currencyCode, now: now, calendar: calendar)
        guard summary.subscriptionCount > 0 else {
            if summary.excludedItemCount > 0 {
                return "You have no subscriptions in \(currencyCode). Items in other currencies aren't added up."
            }
            return "You aren't tracking any subscriptions yet."
        }
        let amount = summary.monthlyBurn.formatted(.currency(code: currencyCode))
        let count = summary.subscriptionCount == 1 ? "1 subscription" : "\(summary.subscriptionCount) subscriptions"
        var sentence = "You spend about \(amount) a month on \(count)."
        if summary.excludedItemCount > 0 {
            sentence += " Items in other currencies aren't included."
        }
        return sentence
    }
}
