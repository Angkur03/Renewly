//
// RootView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import OSLog
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
    let notificationRouter: NotificationRouter

    @AppStorage(AppStorageKey.remindersEnabled) private var remindersEnabled = true
    @AppStorage(AppStorageKey.reminderOffsets) private var reminderOffsetsRaw = ReminderPreferences.defaultOffsetsRaw
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasLoadedEntitlements = false
    @State private var foregroundCount = 0
    @State private var path = NavigationPath()
    @State private var newItemRequest: ItemCategory?
    #if DEBUG
    @State private var isDebugPaywallPresented = false
    #endif

    private var reminderSyncKey: String {
        "\(hasLoadedEntitlements)-\(dependencies.entitlements.isPro)-\(remindersEnabled)-\(reminderOffsetsRaw)-\(foregroundCount)"
    }

    var body: some View {
        NavigationStack(path: $path) {
            DashboardView(
                dependencies: dependencies,
                isUsingTemporaryStorage: isUsingTemporaryStorage,
                onOpenDetails: { path.append($0) },
                newItemRequest: $newItemRequest
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
        .background {
            WidgetSnapshotSync(publisher: dependencies.widgets)
        }
        .onOpenURL { url in
            guard let itemID = WidgetDeepLink.itemID(from: url) else { return }
            notificationRouter.open(itemID: itemID)
        }
        .onChange(of: notificationRouter.pendingItemID, initial: true) {
            openItemFromNotification()
        }
        .onChange(of: notificationRouter.pendingNewItem, initial: true) {
            guard let category = notificationRouter.consumeNewItemRequest() else { return }
            path = NavigationPath()
            newItemRequest = category
        }
        .task {
            await dependencies.entitlements.observeTransactionUpdates()
        }
        #if DEBUG
        .task {
            if DemoTour.isEnabled {
                await runDemoTour()
                return
            }
            let route = UserDefaults.standard.string(forKey: "open_route") ?? ""
            switch route {
            case "insights": path.append(AppRoute.insights)
            case "settings": path.append(AppRoute.settings)
            case "paywall": isDebugPaywallPresented = true
            default:
                if route.hasPrefix(Self.debugItemRoutePrefix) {
                    openDebugItem(titled: String(route.dropFirst(Self.debugItemRoutePrefix.count)))
                }
            }
        }
        .sheet(isPresented: $isDebugPaywallPresented) {
            PaywallView(entitlements: dependencies.entitlements)
        }
        #endif
        .task {
            await dependencies.entitlements.loadProducts()
            await dependencies.entitlements.refreshEntitlements()
            hasLoadedEntitlements = true
        }
        .task(id: reminderSyncKey) {
            #if DEBUG
            seedDemoData()
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

    /// Replaces whatever screen is showing with the reminded item, so Back always returns to the dashboard.
    /// Items deleted after their reminder was delivered are skipped.
    private func openItemFromNotification() {
        guard let itemID = notificationRouter.consume() else { return }
        let descriptor = FetchDescriptor<TrackedItem>(predicate: #Predicate { $0.id == itemID })
        let item: TrackedItem?
        do {
            item = try modelContext.fetch(descriptor).first
        } catch {
            Self.logger.error("Could not load the item for a tapped notification.")
            return
        }
        guard let item else { return }
        var newPath = NavigationPath()
        newPath.append(item)
        path = newPath
    }

    private static let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly", category: "Navigation")

    #if DEBUG
    /// `-open_route "item:Netflix Premium"` opens that item, e.g. for App Store screenshots.
    private static let debugItemRoutePrefix = "item:"

    private func seedDemoData() {
        DemoDataFactory.seedFromLaunchArguments(
            into: modelContext,
            currency: UserDefaults.standard.string(forKey: AppStorageKey.primaryCurrency) ?? CurrencyDefaults.deviceCurrencyCode
        )
    }

    /// Seeds first, because this can run before the sync task that normally seeds demo data.
    private func openDebugItem(titled title: String) {
        seedDemoData()
        let descriptor = FetchDescriptor<TrackedItem>(predicate: #Predicate { $0.title == title })
        do {
            guard let item = try modelContext.fetch(descriptor).first else { return }
            path.append(item)
        } catch {
            Self.logger.error("Could not load the item for a debug route.")
        }
    }

    private func runDemoTour() async {
        let clock = ContinuousClock()
        var nextStop = clock.now
        for (stop, seconds) in DemoTour.stops {
            show(stop)
            // Deadlines come from one start time so slow screens can't push later stops off the video timeline.
            nextStop = nextStop.advanced(by: .seconds(seconds))
            do {
                try await Task.sleep(until: nextStop, clock: clock)
            } catch {
                return
            }
        }
    }

    private func show(_ stop: DemoTour.Stop) {
        switch stop {
        case .dashboard: path = NavigationPath()
        case .item(let title): openDebugItem(titled: title)
        case .insights: path.append(AppRoute.insights)
        case .settings: path.append(AppRoute.settings)
        case .newSubscription: newItemRequest = .subscription
        }
    }
    #endif
}

#Preview("Populated") {
    RootView(dependencies: PreviewData.dependencies(), isUsingTemporaryStorage: false, notificationRouter: NotificationRouter())
        .modelContainer(PreviewData.container(populated: true))
}

#Preview("Empty") {
    RootView(dependencies: PreviewData.dependencies(), isUsingTemporaryStorage: false, notificationRouter: NotificationRouter())
        .modelContainer(PreviewData.container(populated: false))
}
