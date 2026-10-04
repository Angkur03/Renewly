//
// ItemEditorView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftData
import SwiftUI

struct ItemEditorView: View {
    let dependencies: AppDependencies

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKey.remindersEnabled) private var remindersEnabled = true
    @AppStorage(AppStorageKey.reminderOffsets) private var reminderOffsetsRaw = ReminderPreferences.defaultOffsetsRaw
    @Query(filter: #Predicate<TrackedItem> { $0.isNotificationEnabled }) private var alertItems: [TrackedItem]

    @State private var viewModel: ItemEditorViewModel
    @State private var saveTrigger = 0

    init(item: TrackedItem?, defaultCurrency: String, dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: ItemEditorViewModel(item: item, defaultCurrency: defaultCurrency, dependencies: dependencies))
    }

    private var activeAlertItemIDs: Set<UUID> {
        Set(alertItems.map(\.id))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $viewModel.category) {
                        ForEach(ItemCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section("Details") {
                    TextField(viewModel.category == .subscription ? "Service name" : "Product name", text: $viewModel.title)
                        .textInputAutocapitalization(.words)
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("0.00", value: $viewModel.cost, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    CurrencyField(title: "Currency", selection: $viewModel.currencyCode)
                }

                switch viewModel.category {
                case .subscription:
                    subscriptionSection(viewModel: viewModel)
                case .warranty:
                    warrantySection(viewModel: viewModel)
                }

                Section("Receipt") {
                    ReceiptPickerView(
                        previewData: viewModel.receiptPreviewData,
                        onPick: { viewModel.setReceipt($0) },
                        onRemove: { viewModel.removeReceipt() }
                    )
                }

                Section {
                    Toggle(isOn: $viewModel.isNotificationEnabled) {
                        Label("Reminders", systemImage: "bell.badge")
                    }
                } footer: {
                    Text(reminderFooter)
                }

                if let message = viewModel.validationMessage, !viewModel.trimmedTitle.isEmpty {
                    Section {
                        Label(message, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .vaultFont(.body)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .disabled(!viewModel.canSave)
                    }
                }
            }
            .onChange(of: viewModel.isNotificationEnabled) { _, isOn in
                viewModel.notificationToggleChanged(to: isOn, activeAlertItemIDs: activeAlertItemIDs)
            }
            .task {
                viewModel.applyDefaultReminder(activeAlertItemIDs: activeAlertItemIDs)
                await viewModel.loadExistingReceipt()
            }
            .sheet(isPresented: $viewModel.isPaywallPresented) {
                PaywallView(entitlements: dependencies.entitlements)
            }
            .rigidHaptic(trigger: saveTrigger)
            .rigidHaptic(trigger: viewModel.category)
            .errorAlert(message: $viewModel.errorMessage)
            .interactiveDismissDisabled(viewModel.isSaving)
        }
    }

    private var reminderFooter: String {
        let preferences = ReminderPreferences(isEnabled: remindersEnabled, offsetsRaw: reminderOffsetsRaw)
        guard preferences.isEnabled else {
            return "Reminders are turned off for all items in Settings."
        }
        let base = "Alerts at 9:00 AM, \(preferences.scheduleDescription) the date."
        if dependencies.entitlements.isPro {
            return base
        }
        return "\(base) The free plan covers up to \(NotificationManager.freeAlertLimit) items."
    }

    private func subscriptionSection(viewModel: ItemEditorViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return Section("Billing") {
            Picker("Renewal cycle", selection: $viewModel.billingCycle) {
                ForEach(BillingCycle.allCases) { cycle in
                    Text(cycle.title).tag(cycle)
                }
            }
            DatePicker(ItemCategory.subscription.startLabel, selection: $viewModel.startDate, displayedComponents: .date)
            DatePicker(ItemCategory.subscription.expirationLabel, selection: $viewModel.expirationDate, displayedComponents: .date)
            TextField("Cancellation link (optional)", text: $viewModel.cancellationURL)
                .keyboardType(.URL)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    private func warrantySection(viewModel: ItemEditorViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return Section("Warranty") {
            TextField("Retailer (optional)", text: $viewModel.retailer)
            TextField("Serial number (optional)", text: $viewModel.serialNumber)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            DatePicker(ItemCategory.warranty.startLabel, selection: $viewModel.startDate, displayedComponents: .date)
            DatePicker(ItemCategory.warranty.expirationLabel, selection: $viewModel.expirationDate, displayedComponents: .date)
        }
    }

    private func save() {
        saveTrigger += 1
        let alertIDs = activeAlertItemIDs
        Task {
            if await viewModel.save(in: modelContext, activeAlertItemIDs: alertIDs) {
                dismiss()
            }
        }
    }
}

#Preview("New item") {
    ItemEditorView(item: nil, defaultCurrency: "USD", dependencies: PreviewData.dependencies())
        .modelContainer(PreviewData.container(populated: true))
}

#Preview("Edit item") {
    let container = PreviewData.container(populated: false)
    let item = PreviewData.sampleItems()[2]
    container.mainContext.insert(item)
    return ItemEditorView(item: item, defaultCurrency: "USD", dependencies: PreviewData.dependencies())
        .modelContainer(container)
}

#Preview("Notifications denied") {
    ItemEditorView(
        item: nil,
        defaultCurrency: "USD",
        dependencies: PreviewData.dependencies(notificationsAuthorized: false)
    )
    .modelContainer(PreviewData.container(populated: false))
}
