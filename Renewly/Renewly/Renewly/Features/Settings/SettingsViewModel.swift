//
// SettingsViewModel.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var isPaywallPresented = false
    /// Set when a free user taps a Pro-only setting; opens the paywall focused on that feature.
    var lockedFeature: ProFeature?
    var isManageSubscriptionsPresented = false
    var statusMessage: String?
    var errorMessage: String?
    private(set) var authorization: NotificationAuthorization = .authorized

    @ObservationIgnored let entitlements: any EntitlementProviding
    @ObservationIgnored private let notifications: any NotificationScheduling

    init(entitlements: any EntitlementProviding, notifications: any NotificationScheduling) {
        self.entitlements = entitlements
        self.notifications = notifications
    }

    var isPro: Bool { entitlements.isPro }
    var activeSubscription: ActiveSubscription? { entitlements.activeSubscription }
    var isProcessing: Bool { entitlements.isProcessing }
    var isSystemPermissionDenied: Bool { authorization == .denied }

    func isLocked(offset: Int) -> Bool {
        !isPro && !ReminderPreferences.isRequired(offset)
    }

    func refreshAuthorization() async {
        authorization = await notifications.authorizationStatus()
    }

    /// Asks for iOS permission the first time reminders are switched on.
    func remindersTurnedOn() async {
        do {
            _ = try await notifications.requestAuthorization()
        } catch {
            errorMessage = error.userMessage
        }
        await refreshAuthorization()
    }

    func restorePurchases() async {
        do {
            try await entitlements.restorePurchases()
            statusMessage = isPro ? "Renewly Pro has been restored." : "No active Pro subscription was found for this Apple Account."
        } catch {
            errorMessage = error.userMessage
        }
    }
}
