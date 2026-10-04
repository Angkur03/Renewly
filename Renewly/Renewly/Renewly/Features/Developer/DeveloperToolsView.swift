//
// DeveloperToolsView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

#if DEBUG
import SwiftData
import SwiftUI

struct DeveloperToolsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrackedItem.expirationDate) private var items: [TrackedItem]
    @AppStorage(AppStorageKey.primaryCurrency) private var primaryCurrency = CurrencyDefaults.deviceCurrencyCode

    @State private var viewModel: DeveloperToolsViewModel

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: DeveloperToolsViewModel(dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        List {
            Section {
                statusCard
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            Section {
                Toggle(isOn: $viewModel.isProOverrideEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Simulate Pro subscription")
                            Text(viewModel.subscriptionStatusText)
                                .appFont(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: viewModel.isPro ? "crown.fill" : "crown")
                            .foregroundStyle(.yellow)
                    }
                }
                .tint(.yellow)
            } header: {
                Text("Subscription")
            } footer: {
                Text("On: unlimited reminders and Pro status everywhere, without StoreKit. Off: the free plan returns, so only the \(NotificationManager.freeAlertLimit) soonest reminders stay on.")
            }

            Section {
                ForEach(DemoScenario.allCases) { scenario in
                    Button {
                        viewModel.load(scenario, currency: primaryCurrency, into: modelContext)
                    } label: {
                        scenarioRow(scenario)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Demo data")
            } footer: {
                Text("Items use your main currency (\(primaryCurrency)) unless the scenario says otherwise. Reminders start off.")
            }

            Section {
                actionButton("Fill free reminder quota", systemImage: "bell.badge.fill", tint: .indigo) {
                    Task { await viewModel.fillAlertQuota(items: items, in: modelContext) }
                }
                actionButton("Send test notification in \(DeveloperToolsViewModel.testAlertDelaySeconds)s", systemImage: "paperplane.fill", tint: .teal) {
                    Task { await viewModel.sendTestAlert() }
                }
                actionButton("Resync all reminders", systemImage: "arrow.triangle.2.circlepath", tint: .orange) {
                    Task { await viewModel.resyncReminders(in: modelContext) }
                }
            } header: {
                Text("Reminders")
            } footer: {
                Text("\(viewModel.pendingAlertCount) reminder(s) are queued in iOS. After filling the quota, turn on reminders for one more item to trigger the paywall.")
            }

            Section {
                actionButton("Delete all items", systemImage: "trash.fill", tint: .red) {
                    viewModel.isDeleteConfirmationPresented = true
                }
                .disabled(items.isEmpty)
            } header: {
                Text("Reset")
            }
        }
        .appFont(.body)
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle("Developer Tools")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(viewModel.isWorking)
        .overlay {
            if viewModel.isWorking {
                ProgressView()
                    .controlSize(.large)
                    .padding(24)
                    .cardSurface(cornerRadius: 20)
            }
        }
        .confirmationDialog(
            "Delete all \(items.count) items?",
            isPresented: $viewModel.isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                Task { await viewModel.deleteAll(items, in: modelContext) }
            }
        } message: {
            Text("This removes every item, its reminders and receipt images. It cannot be undone.")
        }
        .alert(
            "Done",
            isPresented: Binding(
                get: { viewModel.statusMessage != nil },
                set: { if !$0 { viewModel.statusMessage = nil } }
            ),
            presenting: viewModel.statusMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .errorAlert(message: $viewModel.errorMessage)
        .sensoryFeedback(.success, trigger: viewModel.actionCount)
        .rigidHaptic(trigger: viewModel.isProOverrideEnabled)
        .task(id: viewModel.actionCount) {
            await viewModel.refreshPendingCount()
        }
    }

    private var statusCard: some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Debug build", systemImage: "hammer.fill")
                        .appFont(.headline)
                        .foregroundStyle(.orange)
                    Spacer()
                    BadgeView(viewModel.isPro ? "Pro" : "Free", systemImage: viewModel.isPro ? "crown.fill" : nil, tint: viewModel.isPro ? .yellow : .secondary)
                }
                HStack(spacing: 12) {
                    statTile("Items", value: "\(items.count)", systemImage: "tray.full.fill")
                    statTile("Alerts on", value: viewModel.alertUsageText(for: items), systemImage: "bell.fill")
                    statTile("Queued", value: "\(viewModel.pendingAlertCount)", systemImage: "tray.and.arrow.down.fill")
                }
            }
        }
    }

    private func statTile(_ title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .appFont(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .appFont(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func scenarioRow(_ scenario: DemoScenario) -> some View {
        HStack(spacing: 14) {
            Image(systemName: scenario.systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(scenario.title)
                    .appFont(.body)
                    .fontWeight(.semibold)
                Text(scenario.detail)
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Adds demo items")
    }

    private func actionButton(_ title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label {
                Text(title)
                    .foregroundStyle(tint == .red ? Color.red : Color.primary)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
            }
        }
    }
}

#Preview("Empty") {
    NavigationStack {
        DeveloperToolsView(dependencies: PreviewData.dependencies())
    }
    .modelContainer(PreviewData.container(populated: false))
}

#Preview("Populated, Pro") {
    NavigationStack {
        DeveloperToolsView(dependencies: PreviewData.dependencies(isPro: true))
    }
    .modelContainer(PreviewData.container(populated: true))
}

#Preview("Notifications denied") {
    NavigationStack {
        DeveloperToolsView(dependencies: PreviewData.dependencies(notificationsAuthorized: false))
    }
    .modelContainer(PreviewData.container(populated: true))
}
#endif
