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
        let verb = category == .subscription ? "Renews" : "Expires"
        switch days {
        case ..<(-1): return "\(category == .subscription ? "Ended" : "Expired") \(-days) days ago"
        case -1: return "\(category == .subscription ? "Ended" : "Expired") yesterday"
        case 0: return "\(verb) today"
        case 1: return "\(verb) tomorrow"
        default: return "\(verb) in \(days) days"
        }
    }

    /// e.g. "Trial ends tomorrow", "Trial ends in 5 days".
    static func trialRelative(days: Int) -> String {
        switch days {
        case ..<(-1): "Trial ended \(-days) days ago"
        case -1: "Trial ended yesterday"
        case 0: "Trial ends today"
        case 1: "Trial ends tomorrow"
        default: "Trial ends in \(days) days"
        }
    }

    static func relative(days: Int, category: ItemCategory, isTrial: Bool) -> String {
        isTrial ? trialRelative(days: days) : relative(days: days, category: category)
    }

    /// Compact badge text: "Today", "Tomorrow", "5d left", "Expired".
    static func badge(days: Int) -> String {
        switch days {
        case ..<0: "Expired"
        case 0: "Today"
        case 1: "Tomorrow"
        default: "\(days)d left"
        }
    }

    static func count(_ value: Int, _ singular: String, plural: String? = nil) -> String {
        "\(value) \(value == 1 ? singular : (plural ?? singular + "s"))"
    }
}
