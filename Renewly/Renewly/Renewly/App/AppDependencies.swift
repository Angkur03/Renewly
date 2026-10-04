//
// AppDependencies.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum AppStorageKey {
    static let theme = "app_theme"
    static let primaryCurrency = "primary_currency"
    static let remindersEnabled = "reminders_enabled"
    static let reminderOffsets = "reminder_offsets"
    static let debugProOverride = "debug_pro_override"
}

nonisolated enum CurrencyDefaults {
    static var deviceCurrencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
}

@MainActor
struct AppDependencies {
    let entitlements: any EntitlementProviding
    let notifications: any NotificationScheduling
    let receipts: any ReceiptImageStoring
    let pdfExporter: any ReceiptPDFExporting
    let textRecognizer: any ReceiptTextRecognizing
    let widgets: any WidgetPublishing

    init(
        entitlements: any EntitlementProviding,
        notifications: any NotificationScheduling,
        receipts: any ReceiptImageStoring,
        pdfExporter: any ReceiptPDFExporting,
        textRecognizer: any ReceiptTextRecognizing = VisionReceiptTextRecognizer(),
        widgets: any WidgetPublishing = LiveWidgetPublisher()
    ) {
        self.entitlements = entitlements
        self.notifications = notifications
        self.receipts = receipts
        self.pdfExporter = pdfExporter
        self.textRecognizer = textRecognizer
        self.widgets = widgets
    }

    static func live() -> AppDependencies {
        AppDependencies(
            entitlements: StoreKitEntitlementService(),
            notifications: NotificationManager(),
            receipts: ReceiptImageStore(),
            pdfExporter: ReceiptPDFExporter(),
            textRecognizer: VisionReceiptTextRecognizer(),
            widgets: LiveWidgetPublisher()
        )
    }
}
