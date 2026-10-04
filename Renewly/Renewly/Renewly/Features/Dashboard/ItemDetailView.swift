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
    @State private var viewModel: ItemDetailViewModel

    private var reminders: ReminderPreferences {
        ReminderPreferences(isEnabled: remindersEnabled, offsetsRaw: reminderOffsetsRaw)
    }
    @State private var isEditorPresented = false

    init(item: TrackedItem, dependencies: AppDependencies) {
        self.item = item
        self.dependencies = dependencies
        _viewModel = State(initialValue: ItemDetailViewModel(dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 16) {
                header
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
                Button {
                    Task { await viewModel.exportPDF(for: item, reminders: reminders) }
                } label: {
                    Image(systemName: "doc.richtext")
                }
                .accessibilityLabel("Export PDF")
                .disabled(viewModel.isExporting)

                Button("Edit") { isEditorPresented = true }
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            ItemEditorView(item: item, defaultCurrency: primaryCurrency, dependencies: dependencies)
        }
        .sheet(item: $viewModel.exportedPDF) { pdf in
            PDFPreviewView(pdf: pdf)
        }
        .task(id: item.receiptImagePath) {
            await viewModel.loadReceipt(at: item.receiptImagePath)
        }
        .rigidHaptic(trigger: viewModel.exportedPDF)
        .errorAlert(message: $viewModel.errorMessage)
    }

    private var header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                BadgeView(item.category.title, systemImage: item.category.systemImage)
                Text(item.cost, format: .currency(code: item.currencyCode))
                    .vaultFont(.largeTitle)
                if item.category == .subscription {
                    Text("\(item.billingCycle.title) · \(item.billingCycle.monthlyEquivalent(of: item.cost).formatted(.currency(code: item.currencyCode)))/mo")
                        .vaultFont(.subheadline)
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
                            .vaultFont(.body)
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
                        .vaultFont(.headline)
                    if let receiptImage = viewModel.receiptImage {
                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityLabel("Receipt image")
                    } else if viewModel.receiptLoadFailed {
                        Label("The receipt image could not be loaded.", systemImage: "exclamationmark.triangle")
                            .vaultFont(.footnote)
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
                    Text("Export as PDF")
                        .vaultFont(.headline)
                    Text(item.receiptImagePath == nil
                         ? "Details only. Attach a receipt to include it."
                         : "Details plus the attached \(item.category == .warranty ? "card" : "receipt"), ready to print or share.")
                        .vaultFont(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                if viewModel.isExporting {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .glassSurface(cornerRadius: 20)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isExporting || (item.receiptImagePath != nil && viewModel.receiptImage == nil && !viewModel.receiptLoadFailed))
    }

    private func row(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .vaultFont(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .vaultFont(.body)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let container = PreviewData.container(populated: false)
    let item = PreviewData.sampleItems()[2]
    container.mainContext.insert(item)
    return NavigationStack {
        ItemDetailView(item: item, dependencies: PreviewData.dependencies())
    }
    .modelContainer(container)
}
