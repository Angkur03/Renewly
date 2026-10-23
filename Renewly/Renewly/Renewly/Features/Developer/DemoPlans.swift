//
// DemoPlans.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

#if DEBUG
import Foundation

extension ProPlan {
    /// Prices in minor units (cents, yen), matching the price table in `marketing/ASO-and-Monetization.md`.
    private static let demoPrices: [String: (monthly: Int, yearly: Int, fractionDigits: Int)] = [
        "USD": (499, 1999, 2),
        "EUR": (499, 1999, 2),
        "GBP": (449, 1799, 2),
        "BRL": (1490, 5990, 2),
        "MXN": (6900, 27900, 2),
        "JPY": (600, 2400, 0),
        "CNY": (2800, 11800, 2),
        "INR": (14900, 59900, 2),
    ]

    /// Sample monthly and yearly plans with the one-week trial, for screenshots without StoreKit.
    /// Unknown currencies (e.g. BDT, where the App Store charges in USD) fall back to USD.
    static func demoPlans(currencyCode: String, locale: Locale = .current) -> [ProPlan] {
        let code = demoPrices[currencyCode] == nil ? "USD" : currencyCode
        guard let prices = demoPrices[code] else { return [] }
        let divisor = Decimal(sign: .plus, exponent: prices.fractionDigits, significand: 1)
        let monthly = Decimal(prices.monthly) / divisor
        let yearly = Decimal(prices.yearly) / divisor
        let style = Decimal.FormatStyle.Currency(code: code, locale: locale)
        return [
            ProPlan(kind: .monthly, displayPrice: monthly.formatted(style), price: monthly, pricePerMonthText: nil, freeTrialDays: 7),
            ProPlan(kind: .yearly, displayPrice: yearly.formatted(style), price: yearly, pricePerMonthText: (yearly / 12).formatted(style), freeTrialDays: 7),
        ]
    }
}
#endif
