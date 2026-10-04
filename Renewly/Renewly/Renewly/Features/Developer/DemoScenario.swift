//
// DemoScenario.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

#if DEBUG
import Foundation

nonisolated enum DemoScenario: String, CaseIterable, Identifiable, Sendable {
    case starter
    case expiringSoon
    case expired
    case mixedCurrencies
    case bulk

    static let bulkCount = 30

    var id: String { rawValue }

    var title: String {
        switch self {
        case .starter: "Starter set"
        case .expiringSoon: "Expiring soon"
        case .expired: "Expired items"
        case .mixedCurrencies: "Mixed currencies"
        case .bulk: "Bulk (\(Self.bulkCount) items)"
        }
    }

    var detail: String {
        switch self {
        case .starter: "4 subscriptions and 3 warranties with realistic prices."
        case .expiringSoon: "Items due today, tomorrow and within 2 weeks."
        case .expired: "Lapsed subscriptions and ended warranties."
        case .mixedCurrencies: "EUR, GBP, JPY and BDT to test excluded totals."
        case .bulk: "Lots of rows for scrolling and performance checks."
        }
    }

    var systemImage: String {
        switch self {
        case .starter: "sparkles"
        case .expiringSoon: "clock.badge.exclamationmark"
        case .expired: "calendar.badge.minus"
        case .mixedCurrencies: "coloncurrencysign.circle"
        case .bulk: "square.stack.3d.up"
        }
    }
}

/// Builds demo `TrackedItem`s. Reminders start off so scheduling always goes through the real quota checks.
@MainActor
enum DemoDataFactory {
    static func items(for scenario: DemoScenario, currency: String, now: Date = .now, calendar: Calendar = .current) -> [TrackedItem] {
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: now) ?? now
        }
        func subscription(_ title: String, _ cost: Double, _ cycle: BillingCycle, start: Int, renews: Int, currency code: String = currency, url: String? = nil) -> TrackedItem {
            TrackedItem(
                title: title, category: .subscription, cost: cost, currencyCode: code,
                startDate: day(start), expirationDate: day(renews), billingCycle: cycle, cancellationURL: url
            )
        }
        func warranty(_ title: String, _ cost: Double, retailer: String, serial: String, start: Int, expires: Int, currency code: String = currency) -> TrackedItem {
            TrackedItem(
                title: title, category: .warranty, cost: cost, currencyCode: code,
                startDate: day(start), expirationDate: day(expires), serialNumber: serial, retailer: retailer
            )
        }

        switch scenario {
        case .starter:
            return [
                subscription("Netflix Premium", 22.99, .monthly, start: -200, renews: 18, url: "https://www.netflix.com/cancelplan"),
                subscription("Spotify Duo", 14.99, .monthly, start: -90, renews: 9, url: "https://www.spotify.com/account"),
                subscription("iCloud+ 2TB", 119.88, .yearly, start: -120, renews: 245),
                subscription("Xbox Game Pass", 49.99, .quarterly, start: -40, renews: 50),
                warranty("MacBook Pro 14\"", 2499, retailer: "Apple Store", serial: "C02XK1ABCD12", start: -300, expires: 430),
                warranty("Dyson V15 Detect", 749, retailer: "Dyson", serial: "DY-V15-88213", start: -100, expires: 630),
                warranty("LG C3 OLED 65\"", 1799, retailer: "Best Buy", serial: "LGC3-65-4471", start: -500, expires: 230)
            ]
        case .expiringSoon:
            return [
                subscription("Disney+", 13.99, .monthly, start: -30, renews: 0),
                subscription("ChatGPT Plus", 20, .monthly, start: -29, renews: 1),
                warranty("AirPods Pro", 249, retailer: "Apple Store", serial: "AP2-77120", start: -362, expires: 3),
                subscription("Adobe Creative Cloud", 59.99, .monthly, start: -23, renews: 7),
                warranty("Nintendo Switch OLED", 349, retailer: "Target", serial: "XKW5001234", start: -353, expires: 12)
            ]
        case .expired:
            return [
                subscription("Hulu", 17.99, .monthly, start: -95, renews: -5),
                warranty("Kindle Paperwhite", 149, retailer: "Amazon", serial: "G000-PW-5512", start: -400, expires: -35),
                subscription("NYTimes Digital", 25, .quarterly, start: -120, renews: -1)
            ]
        case .mixedCurrencies:
            return [
                subscription("Deezer Premium", 11.99, .monthly, start: -60, renews: 20, currency: "EUR"),
                subscription("BBC Britbox", 59.99, .yearly, start: -10, renews: 355, currency: "GBP"),
                warranty("Sony α7 IV", 328_000, retailer: "Yodobashi", serial: "SNY-A74-1192", start: -50, expires: 315, currency: "JPY"),
                subscription("Bongo BD", 199, .monthly, start: -15, renews: 15, currency: "BDT"),
                warranty("Walton Fridge", 85_000, retailer: "Walton Plaza", serial: "WLT-RF-9031", start: -200, expires: 530, currency: "BDT")
            ]
        case .bulk:
            let cycles = BillingCycle.allCases
            return (0..<DemoScenario.bulkCount).map { index in
                let renews = (index * 37) % 400 - 20
                if index.isMultiple(of: 3) {
                    return warranty("Demo device #\(index + 1)", Double(150 + index * 45), retailer: "Demo Store", serial: "DEMO-\(1000 + index)", start: renews - 365, expires: renews)
                }
                return subscription("Demo service #\(index + 1)", Double(5 + index % 12) + 0.99, cycles[index % cycles.count], start: renews - 30, renews: renews)
            }
        }
    }
}
#endif
