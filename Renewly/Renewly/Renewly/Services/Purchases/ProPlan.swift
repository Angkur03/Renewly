//
// ProPlan.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum ProPlanKind: String, CaseIterable, Identifiable, Sendable {
    case monthly
    case yearly
    case weekly
    


    static let productIDPrefix = "com.applab.Renewly.pro.version."

    var id: String { rawValue }
    var productID: String { Self.productIDPrefix + rawValue.capitalized }

    var title: String {
        switch self {
        case .weekly: String(localized: "Weekly")
        case .monthly: String(localized: "Monthly")
        case .yearly: String(localized: "Yearly")
        }
    }

    /// Matches the exact IDs from `productID`, so the suffix's capitalization can't drift from the raw value.
    init?(productID: String) {
        guard let kind = Self.allCases.first(where: { $0.productID == productID }) else { return nil }
        self = kind
    }
}

nonisolated struct ProPlan: Identifiable, Equatable, Sendable {
    let kind: ProPlanKind
    let displayPrice: String
    let price: Decimal
    /// e.g. "$1.67" for the yearly plan; `nil` for monthly.
    let pricePerMonthText: String?
    /// Set only when the user is still eligible for the introductory free trial.
    let freeTrialDays: Int?

    var id: String { kind.productID }

    var priceWithPeriod: String {
        switch kind {
        case .monthly: String(localized: "\(displayPrice)/month", comment: "Plan price, e.g. $2.99/month")
        case .yearly: String(localized: "\(displayPrice)/year", comment: "Plan price, e.g. $19.99/year")
        case .weekly:
            String(localized: "\(displayPrice)/week", comment: "Plan price, e.g. $1.99/week")
        }
    }

    static func savingsPercent(monthlyPrice: Decimal, yearlyPrice: Decimal) -> Int? {
        let annualizedMonthly = monthlyPrice * 12
        guard annualizedMonthly > 0, yearlyPrice < annualizedMonthly else { return nil }
        let ratio = NSDecimalNumber(decimal: (annualizedMonthly - yearlyPrice) / annualizedMonthly).doubleValue
        return Int((ratio * 100).rounded(.down))
    }

    static func days(periodValue: Int, unit: TrialUnit) -> Int {
        periodValue * unit.days
    }

    nonisolated enum TrialUnit: Sendable {
        case day, week, month, year

        var days: Int {
            switch self {
            case .day: 1
            case .week: 7
            case .month: 30
            case .year: 365
            }
        }
    }
}

nonisolated struct ActiveSubscription: Equatable, Sendable {
    let kind: ProPlanKind
    let expirationDate: Date?
    let isInFreeTrial: Bool
}
