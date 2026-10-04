//
// SettingsView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import StoreKit
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppStorageKey.theme) private var theme: AppTheme = .system
    @AppStorage(AppStorageKey.primaryCurrency) private var primaryCurrency = CurrencyDefaults.deviceCurrencyCode
    @AppStorage(AppStorageKey.remindersEnabled) private var remindersEnabled = true
    @AppStorage(AppStorageKey.reminderOffsets) private var reminderOffsetsRaw = ReminderPreferences.defaultOffsetsRaw

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: SettingsViewModel

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: SettingsViewModel(
            entitlements: dependencies.entitlements,
            notifications: dependencies.notifications
        ))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Form {
            Section {
                ProStatusCard(
                    isPro: viewModel.isPro,
                    subscription: viewModel.activeSubscription,
                    onUpgrade: { viewModel.isPaywallPresented = true },
                    onManage: { viewModel.isManageSubscriptionsPresented = true }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            notificationsSection

            Section("Appearance") {
                ThemePicker(selection: $theme)
                    .listRowInsets(EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14))
            }

            Section {
                CurrencyField(title: "Main currency", selection: $primaryCurrency)
            } header: {
                Text("Totals")
            } footer: {
                Text("Dashboard totals include only items priced in this currency.")
            }

            Section("Purchases") {
                Button {
                    Task { await viewModel.restorePurchases() }
                } label: {
                    HStack {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                        Spacer()
                        if viewModel.isProcessing {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isProcessing)

                if viewModel.isPro {
                    Button {
                        viewModel.isManageSubscriptionsPresented = true
                    } label: {
                        Label("Manage Subscription", systemImage: "creditcard")
                    }
                }
            }

            #if DEBUG
            Section {
                NavigationLink(value: AppRoute.developerTools) {
                    Label("Developer Tools", systemImage: "hammer.fill")
                }
            } header: {
                Text("Developer")
            } footer: {
                Text("Demo subscriptions, reminder quota and test notifications. Only in debug builds.")
            }
            #endif

            helpSection
        }
        .appFont(.body)
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle("Settings")
        .sheet(isPresented: $viewModel.isPaywallPresented) {
            PaywallView(entitlements: viewModel.entitlements)
        }
        .sheet(item: $viewModel.lockedFeature) { feature in
            PaywallView(entitlements: viewModel.entitlements, highlighting: feature)
        }
        .sheet(isPresented: $viewModel.isMailComposerPresented) {
            MailComposeView(email: viewModel.makeSupportEmail())
                .ignoresSafeArea()
        }
        .alert("Contact Support", isPresented: $viewModel.isSupportAddressPresented) {
            Button("Copy Address") {
                UIPasteboard.general.string = AppLinks.supportAddress
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("No mail app is set up on this device. Email us at \(AppLinks.supportAddress).")
        }
        .manageSubscriptionsSheet(isPresented: $viewModel.isManageSubscriptionsPresented)
        .task(id: viewModel.isManageSubscriptionsPresented) {
            guard !viewModel.isManageSubscriptionsPresented else { return }
            await viewModel.entitlements.refreshEntitlements()
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await viewModel.refreshAuthorization()
        }
        .onChange(of: remindersEnabled) { _, isOn in
            guard isOn else { return }
            Task { await viewModel.remindersTurnedOn() }
        }
        .rigidHaptic(trigger: theme)
        .rigidHaptic(trigger: remindersEnabled)
        .rigidHaptic(trigger: reminderOffsetsRaw)
        .errorAlert(message: $viewModel.errorMessage)
        .alert(
            "Restore Purchases",
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
    }

    private var helpSection: some View {
        Section {
            if let privacyPolicy = AppLinks.privacyPolicy {
                Link(destination: privacyPolicy) {
                    linkRow("Privacy Policy", systemImage: "hand.raised.fill", trailingImage: "arrow.up.right")
                }
            }
            Button(action: contactSupport) {
                linkRow("Contact Support", systemImage: "envelope.fill", detail: AppLinks.supportAddress, trailingImage: "chevron.right")
            }
            .accessibilityHint("Opens an email to support with your device details")
        } header: {
            Text("Help & Privacy")
        } footer: {
            Label("All data stays on this device. No account, no servers, no tracking.", systemImage: "lock.shield")
        }
    }

    private func linkRow(_ title: String, systemImage: String, detail: String? = nil, trailingImage: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(Color.primary)
                if let detail {
                    Text(detail)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 36)
                }
            }
            Spacer()
            Image(systemName: trailingImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    /// In-app composer when Mail is set up, otherwise the default mail app, otherwise show the address to copy.
    private func contactSupport() {
        if MailComposeView.canSendMail {
            viewModel.isMailComposerPresented = true
            return
        }
        guard let url = viewModel.makeSupportEmail().mailtoURL else {
            viewModel.isSupportAddressPresented = true
            return
        }
        openURL(url) { accepted in
            if !accepted {
                viewModel.isSupportAddressPresented = true
            }
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $remindersEnabled) {
                Label("Reminders", systemImage: remindersEnabled ? "bell.badge.fill" : "bell.slash")
            }

            if remindersEnabled {
                if viewModel.isSystemPermissionDenied {
                    permissionDeniedRow
                }
                ForEach(ReminderPreferences.availableOffsets, id: \.self) { offset in
                    reminderOffsetRow(offset)
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text(notificationsFooter)
        }
    }

    private var notificationsFooter: String {
        guard remindersEnabled else {
            return "No reminders will be sent. Items keep their reminder setting and resume when you turn this back on."
        }
        guard viewModel.isPro else {
            return "Alerts arrive at 9:00 AM. The free plan reminds you 7 days before every renewal or warranty ends. Renewly Pro adds 30, 3 and 1 day alerts."
        }
        return "Alerts arrive at 9:00 AM. The 3-day reminder is always included, so you are warned before every renewal or warranty ends."
    }

    @ViewBuilder
    private func reminderOffsetRow(_ offset: Int) -> some View {
        if viewModel.isLocked(offset: offset) {
            lockedOffsetRow(offset)
        } else {
            offsetToggle(offset)
        }
    }

    private func lockedOffsetRow(_ offset: Int) -> some View {
        Button {
            viewModel.lockedFeature = .extraReminders
        } label: {
            HStack {
                Text(ReminderPreferences.title(for: offset))
                    .foregroundStyle(Color.primary)
                Spacer()
                BadgeView("Pro", systemImage: "lock.fill", tint: .yellow)
            }
        }
        .padding(.leading, 8)
        .accessibilityHint("Requires Renewly Pro")
    }

    private var permissionDeniedRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notifications are blocked for Renewly in iOS Settings.", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .appFont(.subheadline)
            Button("Open iOS Settings") {
                guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
                openURL(url)
            }
            .appFont(.subheadline)
        }
        .padding(.vertical, 4)
    }

    private func offsetToggle(_ offset: Int) -> some View {
        let isAlwaysOn = viewModel.isAlwaysOn(offset: offset)
        let binding = Binding<Bool>(
            get: { isAlwaysOn || ReminderPreferences.decode(reminderOffsetsRaw).contains(offset) },
            set: { reminderOffsetsRaw = ReminderPreferences.toggling(offset, isOn: $0, in: reminderOffsetsRaw) }
        )
        return Toggle(isOn: binding) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ReminderPreferences.title(for: offset))
                if isAlwaysOn {
                    Text(viewModel.isPro ? "Always on" : "Included in the free plan")
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(isAlwaysOn)
        .padding(.leading, 8)
    }
}

#Preview("Free") {
    NavigationStack {
        SettingsView(dependencies: PreviewData.dependencies(isPro: false))
    }
}

#Preview("Pro") {
    NavigationStack {
        SettingsView(dependencies: PreviewData.dependencies(isPro: true))
    }
}

#Preview("Light theme") {
    NavigationStack {
        SettingsView(dependencies: PreviewData.dependencies())
    }
    .environment(\.appTheme, .light)
}

#Preview("Notifications blocked") {
    NavigationStack {
        SettingsView(dependencies: PreviewData.dependencies(notificationsAuthorized: false))
    }
}

#Preview("Restore error") {
    NavigationStack {
        SettingsView(dependencies: PreviewData.dependencies(purchaseError: .restoreFailed))
    }
}
