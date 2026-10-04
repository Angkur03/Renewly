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
                            .foregroundStyle(viewModel.cost > ItemEditorViewModel.maxCost ? Color.orange : Color.primary)
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
                    .disabled(!viewModel.canEnableReminders)
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
            .appFont(.body)
            .scrollContentBackground(.hidden)
            .background(AppBackground())
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
            .onChange(of: viewModel.canEnableReminders) { _, canEnable in
                if !canEnable { viewModel.isNotificationEnabled = false }
            }
            .task {
                viewModel.applyDefaultReminder(activeAlertItemIDs: activeAlertItemIDs)
                await viewModel.loadExistingReceipt()
            }
            .sheet(isPresented: $viewModel.isPaywallPresented) {
                PaywallView(entitlements: dependencies.entitlements, highlighting: .unlimitedReminders)
            }
            .rigidHaptic(trigger: saveTrigger)
            .rigidHaptic(trigger: viewModel.category)
            .errorAlert(message: $viewModel.errorMessage)
            .interactiveDismissDisabled(viewModel.isSaving)
        }
    }

    private var reminderFooter: String {
        let isPro = dependencies.entitlements.isPro
        let preferences = ReminderPreferences(isEnabled: remindersEnabled, offsetsRaw: reminderOffsetsRaw).limited(isPro: isPro)
        guard viewModel.canEnableReminders else {
            return "This warranty has already expired, so there is nothing left to remind you about."
        }
        guard preferences.isEnabled else {
            return "Reminders are turned off for all items in Settings."
        }
        let base = "Alerts at 9:00 AM, \(preferences.scheduleDescription) the date."
        if isPro {
            return base
        }
        return "\(base) The free plan covers up to \(NotificationManager.freeAlertLimit) items. Pro adds unlimited items and 30, 7 and 1 day alerts."
    }

    private func subscriptionSection(viewModel: ItemEditorViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return Section {
            Picker("Renewal cycle", selection: $viewModel.billingCycle) {
                ForEach(BillingCycle.allCases) { cycle in
                    Text(cycle.title).tag(cycle)
                }
            }
            DatePicker(ItemCategory.subscription.startLabel, selection: $viewModel.startDate, displayedComponents: .date)
            expirationPicker(viewModel: viewModel)
            TextField("Cancellation link (optional)", text: $viewModel.cancellationURL)
                .keyboardType(.URL)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } header: {
            Text("Billing")
        } footer: {
            if let hint = viewModel.rolloverHint {
                Label(hint, systemImage: "arrow.triangle.2.circlepath")
            }
        }
    }

    private func warrantySection(viewModel: ItemEditorViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return Section {
            TextField("Retailer (optional)", text: $viewModel.retailer)
            TextField("Serial number (optional)", text: $viewModel.serialNumber)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            DatePicker(
                ItemCategory.warranty.startLabel,
                selection: $viewModel.startDate,
                in: ...Date.now,
                displayedComponents: .date
            )
            expirationPicker(viewModel: viewModel)
        } header: {
            Text("Warranty")
        } footer: {
            if viewModel.isExpirationInPast {
                Label("This warranty has already expired. It will be listed under Expired.", systemImage: "clock.arrow.circlepath")
            }
        }
    }

    private func expirationPicker(viewModel: ItemEditorViewModel) -> some View {
        DatePicker(
            viewModel.category.expirationLabel,
            selection: Binding(
                get: { viewModel.expirationDate },
                set: { viewModel.setExpirationDate($0) }
            ),
            in: viewModel.startDate...,
            displayedComponents: .date
        )
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
