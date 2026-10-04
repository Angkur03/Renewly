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
    case insights
    #if DEBUG
    case developerTools
    #endif
}

struct RootView: View {
    let dependencies: AppDependencies
    let isUsingTemporaryStorage: Bool

    @AppStorage(AppStorageKey.remindersEnabled) private var remindersEnabled = true
    @AppStorage(AppStorageKey.reminderOffsets) private var reminderOffsetsRaw = ReminderPreferences.defaultOffsetsRaw
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasLoadedEntitlements = false
    @State private var foregroundCount = 0
    @State private var path = NavigationPath()

    private var reminderSyncKey: String {
        "\(hasLoadedEntitlements)-\(dependencies.entitlements.isPro)-\(remindersEnabled)-\(reminderOffsetsRaw)-\(foregroundCount)"
    }

    var body: some View {
        NavigationStack(path: $path) {
            DashboardView(
                dependencies: dependencies,
                isUsingTemporaryStorage: isUsingTemporaryStorage,
                onOpenDetails: { path.append($0) }
            )
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .settings:
                        SettingsView(dependencies: dependencies)
                    case .insights:
                        InsightsView(entitlements: dependencies.entitlements)
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
        .task {
            await dependencies.entitlements.observeTransactionUpdates()
        }
        #if DEBUG
        .task {
            if UserDefaults.standard.string(forKey: "open_route") == "insights" {
                path.append(AppRoute.insights)
            }
        }
        #endif
        .task {
            await dependencies.entitlements.loadProducts()
            await dependencies.entitlements.refreshEntitlements()
            hasLoadedEntitlements = true
        }
        .task(id: reminderSyncKey) {
            #if DEBUG
            DemoDataFactory.seedFromLaunchArguments(
                into: modelContext,
                currency: UserDefaults.standard.string(forKey: AppStorageKey.primaryCurrency) ?? CurrencyDefaults.deviceCurrencyCode
            )
            #endif
            RenewalRolloverService().rollForward(in: modelContext)
            guard hasLoadedEntitlements else { return }
            await ReminderSyncService(notifications: dependencies.notifications)
                .resync(isPro: dependencies.entitlements.isPro, in: modelContext)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase != .active {
                foregroundCount += 1
            }
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
