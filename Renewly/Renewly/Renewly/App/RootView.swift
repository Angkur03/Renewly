//
// RootView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftData
import SwiftUI

nonisolated enum AppRoute: Hashable, Sendable {
    case settings
    #if DEBUG
    case developerTools
    #endif
}

struct RootView: View {
    let dependencies: AppDependencies
    let isUsingTemporaryStorage: Bool

    @AppStorage(AppStorageKey.font) private var fontFamily: VaultFontFamily = .system
    @AppStorage(AppStorageKey.remindersEnabled) private var remindersEnabled = true
    @AppStorage(AppStorageKey.reminderOffsets) private var reminderOffsetsRaw = ReminderPreferences.defaultOffsetsRaw
    @Environment(\.modelContext) private var modelContext
    @State private var hasLoadedEntitlements = false

    private var reminderSyncKey: String {
        "\(hasLoadedEntitlements)-\(dependencies.entitlements.isPro)-\(remindersEnabled)-\(reminderOffsetsRaw)"
    }

    var body: some View {
        NavigationStack {
            DashboardView(dependencies: dependencies, isUsingTemporaryStorage: isUsingTemporaryStorage)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .settings:
                        SettingsView(dependencies: dependencies)
                    #if DEBUG
                    case .developerTools:
                        DeveloperToolsView(dependencies: dependencies)
                    #endif
                    }
                }
                .navigationDestination(for: TrackedItem.self) { item in
                    ItemDetailView(item: item, dependencies: dependencies)
                }
        }
        .environment(\.isProUser, dependencies.entitlements.isPro)
        .environment(\.vaultFontFamily, fontFamily)
        .task {
            await dependencies.entitlements.observeTransactionUpdates()
        }
        .task {
            await dependencies.entitlements.loadProducts()
            await dependencies.entitlements.refreshEntitlements()
            hasLoadedEntitlements = true
        }
        .task(id: reminderSyncKey) {
            guard hasLoadedEntitlements else { return }
            await ReminderSyncService(notifications: dependencies.notifications)
                .resync(isPro: dependencies.entitlements.isPro, in: modelContext)
        }
    }
}

#Preview("Populated") {
    RootView(dependencies: PreviewData.dependencies(), isUsingTemporaryStorage: false)
        .modelContainer(PreviewData.container(populated: true))
}

#Preview("Empty") {
    RootView(dependencies: PreviewData.dependencies(), isUsingTemporaryStorage: false)
        .modelContainer(PreviewData.container(populated: false))
}
