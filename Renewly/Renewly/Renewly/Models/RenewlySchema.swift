//
// RenewlySchema.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import SwiftData

/// The store layout shipped in 1.0, frozen so existing stores keep a recognisable checksum.
/// Never edit a released schema: copy the live model in here before changing it, then add a new version.
nonisolated enum RenewlySchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TrackedItem.self]
    }

    @Model
    final class TrackedItem {
        @Attribute(.unique) var id: UUID
        var title: String
        var categoryRaw: String
        var cost: Double
        var currencyCode: String
        var startDate: Date
        var expirationDate: Date
        var isNotificationEnabled: Bool
        var serialNumber: String?
        var retailer: String?
        var billingCycleRaw: String
        var cancellationURL: String?
        var receiptImagePath: String?
        var createdAt: Date

        init(
            id: UUID,
            title: String,
            categoryRaw: String,
            cost: Double,
            currencyCode: String,
            startDate: Date,
            expirationDate: Date,
            isNotificationEnabled: Bool,
            billingCycleRaw: String,
            createdAt: Date
        ) {
            self.id = id
            self.title = title
            self.categoryRaw = categoryRaw
            self.cost = cost
            self.currencyCode = currencyCode
            self.startDate = startDate
            self.expirationDate = expirationDate
            self.isNotificationEnabled = isNotificationEnabled
            self.billingCycleRaw = billingCycleRaw
            self.createdAt = createdAt
        }
    }
}

/// 1.1: subscriptions can be marked as free trials (`TrackedItem.trialEndDate`).
nonisolated enum RenewlySchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TrackedItem.self]
    }
}

nonisolated enum RenewlyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [RenewlySchemaV1.self, RenewlySchemaV2.self]
    }

    /// Adding an optional property needs no custom code; existing items get no trial.
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: RenewlySchemaV1.self, toVersion: RenewlySchemaV2.self)]
    }
}

nonisolated enum RenewlyStore {
    static var schema: Schema {
        Schema(versionedSchema: RenewlySchemaV2.self)
    }

    /// - Parameter url: Store location; `nil` uses the default store in Application Support.
    static func makeContainer(inMemory: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let configuration = if let url {
            ModelConfiguration(schema: schema, url: url)
        } else {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        }
        return try ModelContainer(for: schema, migrationPlan: RenewlyMigrationPlan.self, configurations: [configuration])
    }
}
