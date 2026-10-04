//
// RenewlySchemaTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import SwiftData
import Testing
@testable import Renewly

@MainActor
@Suite("Store versioning")
struct RenewlySchemaTests {
    private func temporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "RenewlySchemaTests-\(UUID().uuidString)")
            .appending(path: "default.store")
    }

    private func removeStore(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url.deletingLastPathComponent())
        } catch {
            Issue.record("Could not clean up test store: \(error)")
        }
    }

    @Test func migrationPlanStartsAtVersionOne() {
        #expect(RenewlyMigrationPlan.schemas.count == 1)
        #expect(RenewlySchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(RenewlyMigrationPlan.stages.isEmpty)
    }

    @Test func storesFromBeforeVersioningOpenWithTheirData() throws {
        let url = temporaryStoreURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { removeStore(at: url) }
        let itemID = UUID()

        do {
            let legacySchema = Schema([TrackedItem.self])
            let legacy = try ModelContainer(for: legacySchema, configurations: ModelConfiguration(schema: legacySchema, url: url))
            let context = ModelContext(legacy)
            context.insert(TrackedItem(
                id: itemID, title: "Netflix", category: .subscription, cost: 15.99, currencyCode: "USD",
                startDate: .now, expirationDate: .now.addingTimeInterval(86_400 * 10)
            ))
            try context.save()
        }

        let versioned = try RenewlyStore.makeContainer(url: url)
        let items = try ModelContext(versioned).fetch(FetchDescriptor<TrackedItem>())

        #expect(items.map(\.id) == [itemID])
        #expect(items.first?.title == "Netflix")
    }

    @Test func inMemoryStoreOpens() throws {
        let container = try RenewlyStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        context.insert(TrackedItem(title: "AppleCare", category: .warranty, cost: 199, currencyCode: "USD",
                                   startDate: .now, expirationDate: .now.addingTimeInterval(86_400 * 365)))
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<TrackedItem>()) == 1)
    }
}
