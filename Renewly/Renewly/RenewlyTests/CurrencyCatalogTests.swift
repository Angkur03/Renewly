//
// CurrencyCatalogTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@Suite("CurrencyCatalog")
struct CurrencyCatalogTests {
    private let catalog = CurrencyCatalog(
        codes: ["USD", "EUR", "BDT", "JPY", "GBP", "XAF", "CAD"],
        displayLocale: Locale(identifier: "en_US")
    )

    @Test("Options carry English names, native symbols and flags")
    func optionMetadata() {
        let usd = catalog.option(for: "USD")
        #expect(usd.name == "US Dollar")
        #expect(usd.symbol == "$")
        #expect(usd.flag == "\u{1F1FA}\u{1F1F8}")

        #expect(catalog.option(for: "EUR").symbol == "€")
        #expect(catalog.option(for: "EUR").flag == "\u{1F1EA}\u{1F1FA}")
        #expect(catalog.option(for: "BDT").symbol == "৳")
    }

    @Test("Supranational codes have no flag")
    func supranationalHasNoFlag() {
        #expect(catalog.option(for: "XAF").flag == nil)
        #expect(CurrencyCatalog.flag(for: "XAU") == nil)
    }

    @Test("Unknown codes fall back to the code itself")
    func unknownCodeFallback() {
        let option = catalog.option(for: "ZZZ")
        #expect(option.name == "ZZZ")
        #expect(option.symbol == "ZZZ")
    }

    @Test("All currencies are sorted by name")
    func sortedByName() {
        let names = catalog.all.map(\.name)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    @Test("Empty search returns everything")
    func emptySearch() {
        #expect(catalog.search("  ").count == catalog.all.count)
    }

    @Test("Exact code match ranks first, case-insensitively")
    func exactCodeRanksFirst() {
        #expect(catalog.search("usd").first?.code == "USD")
    }

    @Test("Searching by name, accent-insensitive partial match")
    func searchByName() {
        #expect(catalog.search("taka").map(\.code) == ["BDT"])
        #expect(catalog.search("dollar").map(\.code).contains("CAD"))
        #expect(catalog.search("YEN").map(\.code) == ["JPY"])
    }

    @Test("Searching by symbol")
    func searchBySymbol() {
        #expect(catalog.search("€").map(\.code) == ["EUR"])
        #expect(catalog.search("£").map(\.code) == ["GBP"])
    }

    @Test("No match returns an empty list")
    func noMatch() {
        #expect(catalog.search("bitcoin").isEmpty)
    }

    @Test("Suggestions start with the selection and device currency, without duplicates")
    func suggestionsOrder() {
        let codes = catalog.suggestions(selected: "BDT", device: "USD").map(\.code)
        #expect(codes.prefix(2) == ["BDT", "USD"])
        #expect(Set(codes).count == codes.count)
        #expect(codes.count <= CurrencyCatalog.maxSuggestions)
        #expect(!codes.contains("XAF"))
    }
}
