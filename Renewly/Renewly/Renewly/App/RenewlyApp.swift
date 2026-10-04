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
        let storage = SharedModelContainer.shared
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
}

/// One container per process, shared by the UI and App Intents, which iOS may run before any scene exists.
nonisolated enum SharedModelContainer {
    static let shared: (container: ModelContainer, isTemporary: Bool) = make()

    /// Falls back to an in-memory store so the app stays usable if the on-disk store cannot open.
    /// The on-disk store is left untouched in that case, so a fixed update can still open it.
    private static func make() -> (container: ModelContainer, isTemporary: Bool) {
        do {
            return (try RenewlyStore.makeContainer(), false)
        } catch {
            do {
                return (try RenewlyStore.makeContainer(inMemory: true), true)
            } catch {
                fatalError("SwiftData could not create an in-memory store: \(error)")
            }
        }
    }
}
