//
// CurrencyCatalog.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated struct CurrencyOption: Identifiable, Hashable, Sendable {
    let code: String
    let name: String
    let symbol: String
    /// Regional-indicator flag derived from the ISO code; `nil` for supranational codes such as XAF or XAU.
    let flag: String?
    /// Localized names of the countries and territories that use this currency, sorted by name.
    let countries: [String]

    init(code: String, name: String, symbol: String, flag: String?, countries: [String] = []) {
        self.code = code
        self.name = name
        self.symbol = symbol
        self.flag = flag
        self.countries = countries
    }

    var id: String { code }
}

nonisolated struct CurrencyCatalog: Sendable {
    static let shared = CurrencyCatalog()

    static let popularCodes = ["USD", "EUR", "GBP", "JPY", "CNY", "INR", "BDT", "CAD", "AUD", "CHF", "SGD", "AED"]
    static let maxSuggestions = 8

    /// Every currency in circulation today (ISO 4217 list one), covering all UN member states and their territories.
    /// Foundation's `commonISOCurrencyCodes` still lists retired codes (HRK, VEF, CUC, SLL) and misses newer ones
    /// (VED, XCG, ZWG), while `isoCurrencyCodes` includes ~150 historical currencies, so the list is curated here.
    static let circulatingCodes = [
        "AED", "AFN", "ALL", "AMD", "AOA", "ARS", "AUD", "AWG", "AZN", "BAM", "BBD", "BDT", "BHD", "BIF", "BMD",
        "BND", "BOB", "BRL", "BSD", "BTN", "BWP", "BYN", "BZD", "CAD", "CDF", "CHF", "CLP", "CNY", "COP", "CRC",
        "CUP", "CVE", "CZK", "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "EUR", "FJD", "FKP", "GBP", "GEL",
        "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD", "HNL", "HTG", "HUF", "IDR", "ILS", "INR", "IQD", "IRR",
        "ISK", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KMF", "KPW", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP",
        "LKR", "LRD", "LSL", "LYD", "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRU", "MUR", "MVR", "MWK",
        "MXN", "MYR", "MZN", "NAD", "NGN", "NIO", "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR",
        "PLN", "PYG", "QAR", "RON", "RSD", "RUB", "RWF", "SAR", "SBD", "SCR", "SDG", "SEK", "SGD", "SHP", "SLE",
        "SOS", "SRD", "SSP", "STN", "SVC", "SYP", "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD",
        "TZS", "UAH", "UGX", "USD", "UYU", "UZS", "VED", "VES", "VND", "VUV", "WST", "XAF", "XCD", "XCG", "XOF",
        "XPF", "YER", "ZAR", "ZMW", "ZWG"
    ]

    /// Codes introduced after some iOS releases shipped, so Foundation may not know their names yet.
    private static let fallbackNames = [
        "SLE": "Sierra Leonean Leone",
        "VED": "Venezuelan Digital Bolívar",
        "XCG": "Caribbean Guilder",
        "ZWG": "Zimbabwe Gold"
    ]
    private static let fallbackSymbols = ["XCG": "Cg", "ZWG": "ZiG", "SLE": "Le"]

    let all: [CurrencyOption]
    private let byCode: [String: CurrencyOption]

    init(codes: [String] = CurrencyCatalog.circulatingCodes, displayLocale: Locale = .current) {
        let symbols = Self.nativeSymbols()
        let countries = Self.countriesByCurrency(displayLocale: displayLocale)
        let options = Set(codes).map { code in
            CurrencyOption(
                code: code,
                name: Self.name(for: code, in: displayLocale),
                symbol: symbols[code] ?? Self.fallbackSymbols[code] ?? code,
                flag: Self.flag(for: code),
                countries: countries[code] ?? []
            )
        }
        all = options.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        byCode = Dictionary(uniqueKeysWithValues: options.map { ($0.code, $0) })
    }

    func contains(_ code: String) -> Bool {
        byCode[code] != nil
    }

    func option(for code: String) -> CurrencyOption {
        byCode[code] ?? CurrencyOption(code: code, name: code, symbol: code, flag: Self.flag(for: code))
    }

    /// Selected and device currencies first, then popular ones, without duplicates.
    func suggestions(selected: String, device: String) -> [CurrencyOption] {
        var seen = Set<String>()
        return ([selected, device] + Self.popularCodes)
            .filter { byCode[$0] != nil && seen.insert($0).inserted }
            .prefix(Self.maxSuggestions)
            .map(option(for:))
    }

    /// Matches code, localized name, symbol or a country that uses the currency.
    /// Exact code hits rank first, then code prefixes, name prefixes, name contains, symbol and finally country.
    func search(_ query: String) -> [CurrencyOption] {
        let needle = Self.normalized(query)
        guard !needle.isEmpty else { return all }

        return all
            .compactMap { option -> (rank: Int, option: CurrencyOption)? in
                guard let rank = Self.rank(of: option, for: needle) else { return nil }
                return (rank, option)
            }
            .sorted { lhs, rhs in
                lhs.rank != rhs.rank
                    ? lhs.rank < rhs.rank
                    : lhs.option.name.localizedStandardCompare(rhs.option.name) == .orderedAscending
            }
            .map(\.option)
    }

    private static func rank(of option: CurrencyOption, for needle: String) -> Int? {
        let code = option.code.lowercased()
        let name = normalized(option.name)
        if code == needle { return 0 }
        if code.hasPrefix(needle) { return 1 }
        if name.hasPrefix(needle) { return 2 }
        if name.contains(needle) { return 3 }
        if option.symbol != option.code, normalized(option.symbol).contains(needle) { return 4 }
        let countries = option.countries.map(normalized)
        if countries.contains(where: { $0.hasPrefix(needle) }) { return 5 }
        if needle.count >= 3, countries.contains(where: { $0.contains(needle) }) { return 6 }
        return nil
    }

    static func flag(for code: String) -> String? {
        guard code.count == 3, !code.hasPrefix("X") else { return nil }
        let region = String(code.prefix(2)).uppercased()
        guard region == "EU" || Locale.Region(region).isISORegion else { return nil }
        let scalars = region.unicodeScalars.compactMap { Unicode.Scalar(0x1F1E6 + $0.value - 65) }
        guard scalars.count == 2 else { return nil }
        return String(String.UnicodeScalarView(scalars))
    }

    private static func name(for code: String, in locale: Locale) -> String {
        guard let name = locale.localizedString(forCurrencyCode: code), name != code else {
            return fallbackNames[code] ?? code
        }
        return name
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// The shortest symbol any locale uses for each currency, e.g. "$" rather than "US$", "৳" for BDT.
    private static func nativeSymbols() -> [String: String] {
        var symbols: [String: String] = [:]
        for identifier in Locale.availableIdentifiers {
            let locale = Locale(identifier: identifier)
            guard let code = locale.currency?.identifier,
                  let symbol = locale.currencySymbol,
                  !symbol.isEmpty, symbol != code else {
                continue
            }
            if let existing = symbols[code], existing.count <= symbol.count {
                continue
            }
            symbols[code] = symbol
        }
        return symbols
    }

    /// Maps each currency to the countries and territories whose default currency it is, e.g. USD → Ecuador, Panama…
    private static func countriesByCurrency(displayLocale: Locale) -> [String: [String]] {
        var result: [String: [String]] = [:]
        for region in Locale.Region.isoRegions {
            let locale = Locale(components: Locale.Components(languageCode: "en", languageRegion: region))
            guard let code = locale.currency?.identifier,
                  let name = displayLocale.localizedString(forRegionCode: region.identifier) else { continue }
            result[code, default: []].append(name)
        }
        return result.mapValues { names in
            names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
    }
}
