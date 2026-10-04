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

    var id: String { code }
}

nonisolated struct CurrencyCatalog: Sendable {
    static let shared = CurrencyCatalog()

    static let popularCodes = ["USD", "EUR", "GBP", "JPY", "CNY", "INR", "BDT", "CAD", "AUD", "CHF", "SGD", "AED"]
    static let maxSuggestions = 8

    let all: [CurrencyOption]
    private let byCode: [String: CurrencyOption]

    init(codes: [String] = Locale.commonISOCurrencyCodes, displayLocale: Locale = .current) {
        let symbols = Self.nativeSymbols()
        let options = Set(codes).map { code in
            CurrencyOption(
                code: code,
                name: displayLocale.localizedString(forCurrencyCode: code) ?? code,
                symbol: symbols[code] ?? code,
                flag: Self.flag(for: code)
            )
        }
        all = options.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        byCode = Dictionary(uniqueKeysWithValues: options.map { ($0.code, $0) })
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

    /// Matches code, localized name or symbol. Exact code hits rank first, then code prefixes, then name prefixes.
    func search(_ query: String) -> [CurrencyOption] {
        let needle = Self.normalized(query)
        guard !needle.isEmpty else { return all }

        return all
            .compactMap { option -> (rank: Int, option: CurrencyOption)? in
                let code = option.code.lowercased()
                let name = Self.normalized(option.name)
                if code == needle { return (0, option) }
                if code.hasPrefix(needle) { return (1, option) }
                if name.hasPrefix(needle) { return (2, option) }
                if name.contains(needle) { return (3, option) }
                if option.symbol != option.code, Self.normalized(option.symbol).contains(needle) { return (4, option) }
                return nil
            }
            .sorted { lhs, rhs in
                lhs.rank != rhs.rank
                    ? lhs.rank < rhs.rank
                    : lhs.option.name.localizedStandardCompare(rhs.option.name) == .orderedAscending
            }
            .map(\.option)
    }

    static func flag(for code: String) -> String? {
        guard code.count == 3, !code.hasPrefix("X") else { return nil }
        let region = String(code.prefix(2)).uppercased()
        guard region == "EU" || Locale.Region(region).isISORegion else { return nil }
        let scalars = region.unicodeScalars.compactMap { Unicode.Scalar(0x1F1E6 + $0.value - 65) }
        guard scalars.count == 2 else { return nil }
        return String(String.UnicodeScalarView(scalars))
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
}
