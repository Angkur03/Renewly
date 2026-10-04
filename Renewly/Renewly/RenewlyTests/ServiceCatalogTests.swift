//
// ServiceCatalogTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@Suite("Service catalog")
struct ServiceCatalogTests {
    private let catalog = ServiceCatalog.shared

    @Test("Every service has a unique id and only https manage links")
    func catalogIsWellFormed() throws {
        let ids = catalog.services.map(\.id)
        #expect(Set(ids).count == ids.count)
        for service in catalog.services {
            guard let link = service.manageURL else { continue }
            let url = try #require(URL(string: link), "\(service.name)")
            #expect(url.scheme == "https", "\(service.name)")
            #expect(url.host() != nil, "\(service.name)")
        }
    }

    @Test("Browsing covers every service once, grouped and sorted")
    func groups() {
        let grouped = catalog.groups
        #expect(grouped.flatMap(\.services).count == catalog.services.count)
        for entry in grouped {
            let names = entry.services.map(\.name)
            #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
            #expect(entry.services.allSatisfy { $0.group == entry.group })
        }
    }

    @Test("Search ranks name prefixes first", arguments: [
        ("net", "Netflix"), ("spot", "Spotify Premium"), ("disney plus", "Disney+"), ("NYT", "The New York Times"),
        ("gemini", "Google AI Pro"), ("music", "Amazon Music Unlimited"), ("ícloud", "iCloud+")
    ])
    func searchRanking(query: String, expectedFirst: String) {
        #expect(catalog.search(query).first?.name == expectedFirst)
    }

    @Test func emptyAndUnknownSearches() {
        #expect(catalog.search("  ").isEmpty)
        #expect(catalog.search("zzqx").isEmpty)
    }

    @Test("Suggestions need two characters and stop once the name matches a service")
    func suggestions() {
        #expect(catalog.suggestions(for: "n").isEmpty)
        #expect(catalog.suggestions(for: "ne").first?.name == "Netflix")
        #expect(catalog.suggestions(for: "ne").count <= 3)
        #expect(catalog.suggestions(for: "Netflix").isEmpty)
        #expect(catalog.suggestions(for: "spotify").isEmpty)
    }

    @Test func exactMatchUsesAliases() {
        #expect(catalog.exactMatch(for: "Office 365")?.name == "Microsoft 365")
        #expect(catalog.exactMatch(for: "Disney Plus")?.name == "Disney+")
        #expect(catalog.exactMatch(for: "My gym") == nil)
    }
}

@MainActor
@Suite("Service catalog in the editor")
struct ServiceCatalogEditorTests {
    private func makeViewModel(item: TrackedItem? = nil) -> ItemEditorViewModel {
        ItemEditorViewModel(item: item, defaultCurrency: "USD", dependencies: PreviewData.dependencies())
    }

    @Test("Picking a service fills the name, plan and cancel link")
    func applyFillsFields() throws {
        let viewModel = makeViewModel()
        let service = try #require(ServiceCatalog.shared.exactMatch(for: "Microsoft 365"))

        viewModel.applyService(service)

        #expect(viewModel.title == "Microsoft 365")
        #expect(viewModel.billingCycle == .yearly)
        #expect(viewModel.cancellationURL == ServiceCatalog.microsoftServices)
        #expect(viewModel.serviceSuggestions.isEmpty)
    }

    @Test("A cancel link the user typed is kept, and warranties switch back to subscriptions")
    func applyKeepsTypedLink() throws {
        let viewModel = makeViewModel()
        viewModel.category = .warranty
        viewModel.cancellationURL = "https://example.com/manage"

        viewModel.applyService(try #require(ServiceCatalog.shared.exactMatch(for: "Netflix")))

        #expect(viewModel.category == .subscription)
        #expect(viewModel.cancellationURL == "https://example.com/manage")
    }

    @Test("Suggestions show only while adding a subscription")
    func suggestionsOnlyForNewSubscriptions() {
        let viewModel = makeViewModel()
        viewModel.title = "Spo"
        #expect(viewModel.serviceSuggestions.first?.name == "Spotify Premium")
        #expect(viewModel.canBrowseServices)

        viewModel.category = .warranty
        #expect(viewModel.serviceSuggestions.isEmpty)
        #expect(!viewModel.canBrowseServices)

        let existing = TrackedItem(title: "Spo", category: .subscription, cost: 5, currencyCode: "USD",
                                   startDate: .now, expirationDate: .now.addingTimeInterval(86_400 * 30))
        let editing = makeViewModel(item: existing)
        #expect(editing.serviceSuggestions.isEmpty)
        #expect(!editing.canBrowseServices)
    }
}
