//
// ItemDetailView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftData
import SwiftUI

struct ItemDetailView: View {
    let item: TrackedItem
    let dependencies: AppDependencies

    @AppStorage(AppStorageKey.primaryCurrency) private var primaryCurrency = CurrencyDefaults.deviceCurrencyCode
    @AppStorage(AppStorageKey.remindersEnabled) private var remindersEnabled = true
    @AppStorage(AppStorageKey.reminderOffsets) private var reminderOffsetsRaw = ReminderPreferences.defaultOffsetsRaw
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: ItemDetailViewModel
    @State private var isEditorPresented = false
    @State private var isConfirmingDelete = false
    @State private var now = Date.now

    private var reminders: ReminderPreferences {
        ReminderPreferences(isEnabled: remindersEnabled, offsetsRaw: reminderOffsetsRaw)
            .limited(isPro: viewModel.isPro)
    }

    /// A deleted model must not be read; its backing data is gone.
    private var isItemGone: Bool {
        item.isDeleted || item.modelContext == nil
    }

    init(item: TrackedItem, dependencies: AppDependencies) {
        self.item = item
        self.dependencies = dependencies
        _viewModel = State(initialValue: ItemDetailViewModel(dependencies: dependencies))
    }

    var body: some View {
        if isItemGone {
            ContentUnavailableView(
                "Item removed",
                systemImage: "trash",
                description: Text("This item is no longer tracked.")
            )
            .background(AppBackground())
        } else {
            content
        }
    }

    private var content: some View {
        @Bindable var viewModel = viewModel

        return ScrollView {
            VStack(spacing: 16) {
                header
                TimeLeftCard(item: item, now: now)
                detailsCard
                receiptCard
                exportCard
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Edit") { isEditorPresented = true }
                    .disabled(viewModel.isDeleting)

                Menu {
                    Button {
                        Task { await viewModel.exportPDF(for: item, reminders: reminders) }
                    } label: {
                        Label(viewModel.isPro ? "Export PDF" : "Export PDF (Pro)", systemImage: viewModel.isPro ? "doc.richtext" : "lock.fill")
                    }
                    .disabled(viewModel.isExporting)

                    if let url = item.validCancellationURL {
                        Link(destination: url) {
                            Label("Manage or cancel", systemImage: "arrow.up.right.square")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More actions")
                .disabled(viewModel.isDeleting)
            }
        }
        .confirmationDialog("Delete \(item.title)?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.delete(item, in: modelContext) {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Its reminders and receipt photo will be removed too. This can't be undone.")
        }
        .sheet(isPresented: $isEditorPresented) {
            ItemEditorView(item: item, defaultCurrency: primaryCurrency, dependencies: dependencies)
        }
        .sheet(item: $viewModel.exportedPDF) { pdf in
            PDFPreviewView(pdf: pdf)
        }
        .sheet(item: $viewModel.paywallFeature) { feature in
            PaywallView(entitlements: viewModel.entitlements, highlighting: feature)
        }
        .task(id: item.receiptImagePath) {
            await viewModel.loadReceipt(at: item.receiptImagePath)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { now = .now }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            now = .now
        }
        .rigidHaptic(trigger: viewModel.exportedPDF)
        .errorAlert(message: $viewModel.errorMessage)
    }

    private var header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                BadgeView(item.category.title, systemImage: item.category.systemImage)
                Text(item.cost, format: .currency(code: item.currencyCode))
                    .appFont(.largeTitle)
                if item.category == .subscription {
                    Text("\(item.billingCycle.title) · \(item.billingCycle.monthlyEquivalent(of: item.cost).formatted(.currency(code: item.currencyCode)))/mo")
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var detailsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                row(item.category.startLabel, value: item.startDate.formatted(date: .long, time: .omitted))
                row(item.category.expirationLabel, value: item.expirationDate.formatted(date: .long, time: .omitted))
                row("Reminders", value: ItemDetailViewModel.reminderSummary(for: item, reminders: reminders))
                if let retailer = item.retailer, !retailer.isEmpty {
                    row("Retailer", value: retailer)
                }
                if let serial = item.serialNumber, !serial.isEmpty {
                    row("Serial number", value: serial)
                        .textSelection(.enabled)
                }
                if let url = item.validCancellationURL {
                    Link(destination: url) {
                        Label("Manage or cancel", systemImage: "arrow.up.right.square")
                            .appFont(.body)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var receiptCard: some View {
        if item.receiptImagePath != nil {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.category == .warranty ? "Warranty card / receipt" : "Receipt")
                        .appFont(.headline)
                    if let receiptImage = viewModel.receiptImage {
                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityLabel("Receipt image")
                    } else if viewModel.receiptLoadFailed {
                        Label("The receipt image could not be loaded.", systemImage: "exclamationmark.triangle")
                            .appFont(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var exportCard: some View {
        Button {
            Task { await viewModel.exportPDF(for: item, reminders: reminders) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "doc.richtext.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Export as PDF")
                            .appFont(.headline)
                        if !viewModel.isPro {
                            BadgeView("Pro", systemImage: "crown.fill", tint: .yellow)
                        }
                    }
                    Text(item.receiptImagePath == nil
                         ? "Details only. Attach a receipt to include it."
                         : "Details plus the attached \(item.category == .warranty ? "card" : "receipt"), ready to print or share.")
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                if viewModel.isExporting {
                    ProgressView()
                } else if !viewModel.isPro {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .cardSurface(cornerRadius: 20)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isExporting || (viewModel.isPro && item.receiptImagePath != nil && viewModel.receiptImage == nil && !viewModel.receiptLoadFailed))
    }

    private func row(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .appFont(.body)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Warranty") {
    let container = PreviewData.container(populated: false)
    let item = PreviewData.sampleItems()[2]
    container.mainContext.insert(item)
    return NavigationStack {
        ItemDetailView(item: item, dependencies: PreviewData.dependencies())
    }
    .modelContainer(container)
}

#Preview("Subscription") {
    let container = PreviewData.container(populated: false)
    let item = PreviewData.sampleItems()[0]
    container.mainContext.insert(item)
    return NavigationStack {
        ItemDetailView(item: item, dependencies: PreviewData.dependencies())
    }
    .modelContainer(container)
}

#Preview("Removed item") {
    NavigationStack {
        ItemDetailView(item: PreviewData.sampleItems()[0], dependencies: PreviewData.dependencies())
    }
    .modelContainer(PreviewData.container(populated: false))
}
