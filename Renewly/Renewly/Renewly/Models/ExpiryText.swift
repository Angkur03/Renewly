//
// ExpiryText.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum ExpiryText {
    /// e.g. "Renews tomorrow", "Expires in 5 days", "Expired 3 days ago".
    static func relative(days: Int, category: ItemCategory) -> String {
        switch category {
        case .subscription: subscriptionRelative(days: days)
        case .warranty: warrantyRelative(days: days)
        }
    }

    private static func subscriptionRelative(days: Int) -> String {
        switch days {
        case ..<(-1): String(localized: "Ended \(-days) days ago")
        case -1: String(localized: "Ended yesterday")
        case 0: String(localized: "Renews today")
        case 1: String(localized: "Renews tomorrow")
        default: String(localized: "Renews in \(days) days")
        }
    }

    private static func warrantyRelative(days: Int) -> String {
        switch days {
        case ..<(-1): String(localized: "Expired \(-days) days ago")
        case -1: String(localized: "Expired yesterday")
        case 0: String(localized: "Expires today")
        case 1: String(localized: "Expires tomorrow")
        default: String(localized: "Expires in \(days) days")
        }
    }

    /// e.g. "Trial ends tomorrow", "Trial ends in 5 days".
    static func trialRelative(days: Int) -> String {
        switch days {
        case ..<(-1): String(localized: "Trial ended \(-days) days ago")
        case -1: String(localized: "Trial ended yesterday")
        case 0: String(localized: "Trial ends today")
        case 1: String(localized: "Trial ends tomorrow")
        default: String(localized: "Trial ends in \(days) days")
        }
    }

    static func relative(days: Int, category: ItemCategory, isTrial: Bool) -> String {
        isTrial ? trialRelative(days: days) : relative(days: days, category: category)
    }

    /// Compact badge text: "Today", "Tomorrow", "5d left", "Expired".
    static func badge(days: Int) -> String {
        switch days {
        case ..<0: String(localized: "Expired")
        case 0: String(localized: "Today")
        case 1: String(localized: "Tomorrow")
        default: String(localized: "\(days)d left", comment: "Short badge: days remaining")
        }
    }
}
