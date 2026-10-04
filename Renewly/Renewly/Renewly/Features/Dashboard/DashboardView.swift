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
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \TrackedItem.expirationDate) private var items: [TrackedItem]
    @AppStorage(AppStorageKey.primaryCurrency) private var primaryCurrency = CurrencyDefaults.deviceCurrencyCode

    @State private var viewModel: DashboardViewModel
    @State private var editorTarget: EditorTarget?
    @State private var searchText = ""
    @State private var pendingDeletion: TrackedItem?
    /// Re-evaluated on foreground and at midnight so "days left" badges never go stale.
    @State private var now = Date.now

    init(dependencies: AppDependencies, isUsingTemporaryStorage: Bool) {
        self.dependencies = dependencies
        self.isUsingTemporaryStorage = isUsingTemporaryStorage
        _viewModel = State(initialValue: DashboardViewModel(dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        let sections = viewModel.sections(from: items, query: searchText, now: now)

        List {
            Group {
                if isUsingTemporaryStorage {
                    temporaryStorageBanner
                }
                summaryCard
                if !items.isEmpty {
                    FilterChipsBar(selection: $viewModel.filter, counts: viewModel.counts(for: items, now: now))
                }
            }
            .dashboardRow()

            if sections.isEmpty {
                emptyState
                    .dashboardRow()
            } else {
                if !sections.upcoming.isEmpty {
                    sectionHeader("Upcoming", count: sections.upcoming.count, systemImage: "calendar")
                    ForEach(sections.upcoming) { item in
                        card(for: item)
                            .dashboardRow()
                    }
                }
                if !sections.expired.isEmpty {
                    sectionHeader("Expired", count: sections.expired.count, systemImage: "clock.arrow.circlepath")
                    ForEach(sections.expired) { item in
                        card(for: item)
                            .opacity(0.75)
                            .dashboardRow()
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .animation(.snappy, value: viewModel.filter)
        .animation(.snappy, value: searchText)
        .modifier(DashboardSearch(text: $searchText, isEnabled: !items.isEmpty))
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { now = .now }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            now = .now
        }
        .confirmationDialog(
            pendingDeletion.map { "Delete \($0.title)?" } ?? "Delete item?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { item in
            Button("Delete", role: .destructive) {
                Task { await viewModel.delete(item, in: modelContext) }
            }
        } message: { _ in
            Text("Its reminders and receipt photo will be removed too. This can't be undone.")
        }
        .navigationTitle("Renewly")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.insights) {
                    Image(systemName: "chart.pie")
                }
                .accessibilityLabel("Spending insights")
                .disabled(items.isEmpty)
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
            ItemCardView(item: item, now: now)
        }
        .simultaneousGesture(TapGesture().onEnded { viewModel.registerInteraction() })
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pendingDeletion = item
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
                pendingDeletion = item
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var summaryCard: some View {
        let summary = SummaryHeaderCard(
            summary: viewModel.summary(for: items, currencyCode: primaryCurrency, now: now),
            showsInsightsHint: !items.isEmpty,
            isInsightsLocked: !dependencies.entitlements.isPro
        )
        if items.isEmpty {
            summary
        } else {
            ZStack {
                NavigationLink(value: AppRoute.insights) { EmptyView() }
                    .opacity(0)
                summary
            }
            .accessibilityHint("Opens spending insights")
        }
    }

    private func sectionHeader(_ title: String, count: Int, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Label(title, systemImage: systemImage)
                .appFont(.subheadline)
                .fontWeight(.semibold)
            Text(count, format: .number)
                .appFont(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Spacer()
        }
        .foregroundStyle(.secondary)
        .padding(.top, 8)
        .accessibilityAddTraits(.isHeader)
        .dashboardRow()
    }

    @ViewBuilder
    private var emptyState: some View {
        if !items.isEmpty, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            noItemsState
        }
    }

    private var noItemsState: some View {
        VStack(spacing: 12) {
            Image(systemName: items.isEmpty ? "tray" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(items.isEmpty ? "Nothing tracked yet" : "No matching items")
                .appFont(.headline)
            Text(items.isEmpty
                 ? "Add a subscription or warranty to start getting reminders before they renew or expire."
                 : "Try a different filter.")
                .appFont(.subheadline)
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
        .appFont(.footnote)
        .foregroundStyle(.orange)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 16)
    }
}

/// Search is pointless with nothing tracked, so the field only appears once there is at least one item.
private struct DashboardSearch: ViewModifier {
    @Binding var text: String
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(
                text: $text,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search name, store or serial"
            )
        } else {
            content
        }
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
