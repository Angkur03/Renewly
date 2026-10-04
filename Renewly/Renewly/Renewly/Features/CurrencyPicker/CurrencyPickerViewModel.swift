//
// CurrencyPickerViewModel.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation

@Observable
@MainActor
final class CurrencyPickerViewModel {
    var searchText = ""

    let selectedCode: String
    @ObservationIgnored private let catalog: CurrencyCatalog
    @ObservationIgnored private let deviceCode: String

    init(
        selectedCode: String,
        catalog: CurrencyCatalog = .shared,
        deviceCode: String = CurrencyDefaults.deviceCurrencyCode
    ) {
        self.selectedCode = selectedCode
        self.catalog = catalog
        self.deviceCode = deviceCode
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var suggestions: [CurrencyOption] {
        isSearching ? [] : catalog.suggestions(selected: selectedCode, device: deviceCode)
    }

    var results: [CurrencyOption] {
        catalog.search(searchText)
    }

    var resultsTitle: String {
        isSearching ? "Results" : "All currencies · \(catalog.all.count)"
    }
}
