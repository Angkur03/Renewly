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

    static let productIDPrefix = "com.beleiveinAllahRenewly.Renewly.pro."

    var id: String { rawValue }
    var productID: String { Self.productIDPrefix + rawValue }

    var title: String {
        switch self {
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }

    var periodNoun: String {
        switch self {
        case .monthly: "month"
        case .yearly: "year"
        }
    }

    init?(productID: String) {
        guard productID.hasPrefix(Self.productIDPrefix) else { return nil }
        self.init(rawValue: String(productID.dropFirst(Self.productIDPrefix.count)))
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

    var priceWithPeriod: String { "\(displayPrice)/\(kind.periodNoun)" }

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
