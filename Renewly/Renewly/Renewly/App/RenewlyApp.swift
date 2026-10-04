//
// RenewlyApp.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftData
import SwiftUI

@main
struct RenewlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppStorageKey.theme) private var theme: AppTheme = .system
    @State private var isShowingSplash = true

    private let modelContainer: ModelContainer
    private let isUsingTemporaryStorage: Bool
    private let dependencies: AppDependencies

    init() {
        let storage = Self.makeModelContainer()
        modelContainer = storage.container
        isUsingTemporaryStorage = storage.isTemporary
        dependencies = .live()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView(
                    dependencies: dependencies,
                    isUsingTemporaryStorage: isUsingTemporaryStorage,
                    notificationRouter: appDelegate.notificationRouter
                )
                if isShowingSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.45)) {
                            isShowingSplash = false
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
                    .zIndex(1)
                }
            }
            .environment(\.appTheme, theme)
            .task {
                InterfaceStyleController.apply(theme, animated: false)
            }
            .onChange(of: theme) { _, newTheme in
                InterfaceStyleController.apply(newTheme, animated: true)
            }
        }
        .modelContainer(modelContainer)
    }

    /// Falls back to an in-memory store so the app stays usable if the on-disk store cannot open.
    private static func makeModelContainer() -> (container: ModelContainer, isTemporary: Bool) {
        let schema = Schema([TrackedItem.self])
        do {
            let configuration = ModelConfiguration(schema: schema)
            return (try ModelContainer(for: schema, configurations: [configuration]), false)
        } catch {
            do {
                let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return (try ModelContainer(for: schema, configurations: [configuration]), true)
            } catch {
                fatalError("SwiftData could not create an in-memory store: \(error)")
            }
        }
    }
}
