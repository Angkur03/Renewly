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
        let due = upcoming(items, within: days, now: now, calendar: calendar)
        guard !due.isEmpty else {
            return days == 1
                ? String(localized: "Nothing renews or expires today or tomorrow.")
                : String(localized: "Nothing renews or expires in the next \(days) days.")
        }
        var phrases = due.prefix(spokenItemLimit).map { phrase(for: $0, now: now, calendar: calendar) }
        if due.count > spokenItemLimit {
            phrases.append(String(localized: "\(due.count - spokenItemLimit) more"))
        }
        let list = phrases.formatted(.list(type: .and))
        let count = String(localized: "\(due.count) things")
        return days == 1
            ? String(localized: "\(count) today or tomorrow: \(list).")
            : String(localized: "\(count) in the next \(days) days: \(list).")
    }

    /// e.g. "Netflix renews tomorrow", "YouTube Premium's trial ends in 3 days", "AirPods Pro warranty expires today".
    static func phrase(for item: ItemSnapshot, now: Date, calendar: Calendar = .current) -> String {
        let days = max(0, item.daysUntilExpiration(from: now, calendar: calendar))
        let title = item.title
        switch WidgetSnapshotBuilder.kind(of: item, calendar: calendar) {
        case .subscription:
            return switch days {
            case 0: String(localized: "\(title) renews today")
            case 1: String(localized: "\(title) renews tomorrow")
            default: String(localized: "\(title) renews in \(days) days")
            }
        case .trial:
            return switch days {
            case 0: String(localized: "\(title)'s trial ends today")
            case 1: String(localized: "\(title)'s trial ends tomorrow")
            default: String(localized: "\(title)'s trial ends in \(days) days")
            }
        case .warranty:
            return switch days {
            case 0: String(localized: "\(title) warranty expires today")
            case 1: String(localized: "\(title) warranty expires tomorrow")
            default: String(localized: "\(title) warranty expires in \(days) days")
            }
        }
    }

    static func spendDialog(_ items: [ItemSnapshot], currencyCode: String, now: Date, calendar: Calendar = .current) -> String {
        let summary = DashboardSummary.make(from: items, currencyCode: currencyCode, now: now, calendar: calendar)
        guard summary.subscriptionCount > 0 else {
            if summary.excludedItemCount > 0 {
                return String(localized: "You have no subscriptions in \(currencyCode). Items in other currencies aren't added up.")
            }
            return String(localized: "You aren't tracking any subscriptions yet.")
        }
        let amount = summary.monthlyBurn.formatted(.currency(code: currencyCode))
        let count = String(localized: "\(summary.subscriptionCount) subscriptions")
        let sentence = String(localized: "You spend about \(amount) a month on \(count).")
        guard summary.excludedItemCount > 0 else { return sentence }
        return "\(sentence) \(String(localized: "Items in other currencies aren't included."))"
    }
}
