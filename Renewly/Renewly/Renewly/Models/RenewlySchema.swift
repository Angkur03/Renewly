//
// RenewlySchema.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import SwiftData

/// The store layout shipped in 1.0. Never edit a released schema: when `TrackedItem` changes, freeze a copy of the
/// old model inside its schema enum, add `RenewlySchemaV2` and a migration stage, and point `current` at it.
nonisolated enum RenewlySchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TrackedItem.self]
    }
}

nonisolated enum RenewlyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [RenewlySchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

nonisolated enum RenewlyStore {
    static var schema: Schema {
        Schema(versionedSchema: RenewlySchemaV1.self)
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
