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

    @Test func migrationPlanGoesFromVersionOneToTwo() {
        #expect(RenewlyMigrationPlan.schemas.count == 2)
        #expect(RenewlySchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(RenewlySchemaV2.versionIdentifier == Schema.Version(2, 0, 0))
        #expect(RenewlyMigrationPlan.stages.count == 1)
    }

    /// Writes a store the way 1.0 did, then opens it with the current app.
    private func migratedItems(legacySchema: Schema) throws -> [TrackedItem] {
        let url = temporaryStoreURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { removeStore(at: url) }

        do {
            let legacy = try ModelContainer(for: legacySchema, configurations: ModelConfiguration(schema: legacySchema, url: url))
            let context = ModelContext(legacy)
            context.insert(RenewlySchemaV1.TrackedItem(
                id: Self.legacyItemID, title: "Netflix", categoryRaw: ItemCategory.subscription.rawValue, cost: 15.99,
                currencyCode: "USD", startDate: .now, expirationDate: .now.addingTimeInterval(86_400 * 10),
                isNotificationEnabled: true, billingCycleRaw: BillingCycle.monthly.rawValue, createdAt: .now
            ))
            try context.save()
        }

        let current = try RenewlyStore.makeContainer(url: url)
        return try ModelContext(current).fetch(FetchDescriptor<TrackedItem>())
    }

    private static let legacyItemID = UUID()

    @Test func versionOneStoresMigrateWithTheirData() throws {
        let items = try migratedItems(legacySchema: Schema(versionedSchema: RenewlySchemaV1.self))

        #expect(items.map(\.id) == [Self.legacyItemID])
        #expect(items.first?.title == "Netflix")
        #expect(items.first?.isNotificationEnabled == true)
        #expect(items.first?.trialEndDate == nil)
    }

    @Test func storesFromBeforeVersioningMigrateWithTheirData() throws {
        let items = try migratedItems(legacySchema: Schema([RenewlySchemaV1.TrackedItem.self]))

        #expect(items.map(\.id) == [Self.legacyItemID])
        #expect(items.first?.trialEndDate == nil)
    }

    @Test func trialEndDatePersists() throws {
        let container = try RenewlyStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let trialEnd = Date.now.addingTimeInterval(86_400 * 7)
        context.insert(TrackedItem(title: "YouTube Premium", category: .subscription, cost: 13.99, currencyCode: "USD",
                                   startDate: .now, expirationDate: trialEnd, trialEndDate: trialEnd))
        try context.save()

        let item = try #require(try context.fetch(FetchDescriptor<TrackedItem>()).first)
        #expect(item.isInTrial())
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
