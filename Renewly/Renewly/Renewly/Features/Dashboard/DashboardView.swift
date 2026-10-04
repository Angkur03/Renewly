//
// DashboardView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftData
import SwiftUI

enum EditorTarget: Identifiable {
    case new
    case edit(TrackedItem)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let item): item.id.uuidString
        }
    }

    var item: TrackedItem? {
        switch self {
        case .new: nil
        case .edit(let item): item
        }
    }
}

struct DashboardView: View {
    let dependencies: AppDependencies
    let isUsingTemporaryStorage: Bool

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrackedItem.expirationDate) private var items: [TrackedItem]
    @AppStorage(AppStorageKey.primaryCurrency) private var primaryCurrency = CurrencyDefaults.deviceCurrencyCode

    @State private var viewModel: DashboardViewModel
    @State private var editorTarget: EditorTarget?

    init(dependencies: AppDependencies, isUsingTemporaryStorage: Bool) {
        self.dependencies = dependencies
        self.isUsingTemporaryStorage = isUsingTemporaryStorage
        _viewModel = State(initialValue: DashboardViewModel(dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        let visibleItems = viewModel.visibleItems(from: items)

        List {
            Group {
                if isUsingTemporaryStorage {
                    temporaryStorageBanner
                }
                SummaryHeaderCard(summary: viewModel.summary(for: items, currencyCode: primaryCurrency))
                FilterChipsBar(selection: $viewModel.filter)
            }
            .dashboardRow()

            if visibleItems.isEmpty {
                emptyState
                    .dashboardRow()
            } else {
                ForEach(visibleItems) { item in
                    card(for: item)
                        .dashboardRow()
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .animation(.snappy, value: viewModel.filter)
        .navigationTitle("Renewly")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.registerInteraction()
                    editorTarget = .new
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Add item")
            }
        }
        .sheet(item: $editorTarget) { target in
            ItemEditorView(item: target.item, defaultCurrency: primaryCurrency, dependencies: dependencies)
        }
        .rigidHaptic(trigger: viewModel.interactionCount)
        .errorAlert(message: $viewModel.errorMessage)
    }

    private func card(for item: TrackedItem) -> some View {
        ZStack {
            NavigationLink(value: item) { EmptyView() }
                .opacity(0)
            ItemCardView(item: item)
        }
        .simultaneousGesture(TapGesture().onEnded { viewModel.registerInteraction() })
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task { await viewModel.delete(item, in: modelContext) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                editorTarget = .edit(item)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.indigo)
        }
        .contextMenu {
            Button {
                editorTarget = .edit(item)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Task { await viewModel.delete(item, in: modelContext) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: items.isEmpty ? "tray" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(items.isEmpty ? "Nothing tracked yet" : "No matching items")
                .vaultFont(.headline)
            Text(items.isEmpty
                 ? "Add a subscription or warranty to start getting reminders before they renew or expire."
                 : "Try a different filter.")
                .vaultFont(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if items.isEmpty {
                Button("Add your first item") {
                    viewModel.registerInteraction()
                    editorTarget = .new
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var temporaryStorageBanner: some View {
        Label(
            "Your data could not be loaded from storage. Changes made now will not be saved after you close the app.",
            systemImage: "exclamationmark.triangle.fill"
        )
        .vaultFont(.footnote)
        .foregroundStyle(.orange)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(cornerRadius: 16)
    }
}

private extension View {
    func dashboardRow() -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
}

#Preview("Populated") {
    NavigationStack {
        DashboardView(dependencies: PreviewData.dependencies(), isUsingTemporaryStorage: false)
    }
    .modelContainer(PreviewData.container(populated: true))
}

#Preview("Empty") {
    NavigationStack {
        DashboardView(dependencies: PreviewData.dependencies(), isUsingTemporaryStorage: false)
    }
    .modelContainer(PreviewData.container(populated: false))
}

#Preview("Storage error") {
    NavigationStack {
        DashboardView(dependencies: PreviewData.dependencies(), isUsingTemporaryStorage: true)
    }
    .modelContainer(PreviewData.container(populated: true))
}
