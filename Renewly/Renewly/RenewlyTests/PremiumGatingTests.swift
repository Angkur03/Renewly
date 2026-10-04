//
// PremiumGatingTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@MainActor
@Suite("Premium gating")
struct PremiumGatingTests {
    private func makeItem() -> TrackedItem {
        TrackedItem(
            title: "MacBook Pro", category: .warranty, cost: 2499, currencyCode: "USD",
            startDate: .now, expirationDate: .now.addingTimeInterval(86_400 * 365)
        )
    }

    private func dependencies(entitlements: MockEntitlementService) -> AppDependencies {
        AppDependencies(
            entitlements: entitlements,
            notifications: MockNotificationScheduler(),
            receipts: InMemoryReceiptStore(),
            pdfExporter: ReceiptPDFExporter()
        )
    }

    @Test("Free users get the paywall instead of a PDF")
    func pdfExportIsLockedForFree() async {
        let viewModel = ItemDetailViewModel(dependencies: dependencies(entitlements: MockEntitlementService(isPro: false)))

        await viewModel.exportPDF(for: makeItem(), reminders: ReminderPreferences())

        #expect(viewModel.paywallFeature == .pdfExport)
        #expect(viewModel.exportedPDF == nil)
    }

    @Test("Pro users export straight away")
    func pdfExportWorksForPro() async {
        let viewModel = ItemDetailViewModel(dependencies: dependencies(entitlements: MockEntitlementService(isPro: true)))

        await viewModel.exportPDF(for: makeItem(), reminders: ReminderPreferences())

        #expect(viewModel.paywallFeature == nil)
        #expect(viewModel.exportedPDF != nil)
    }

    @Test("Subscribing from the paywall unlocks export immediately")
    func purchaseUnlocksExport() async {
        let entitlements = MockEntitlementService(isPro: false)
        let viewModel = ItemDetailViewModel(dependencies: dependencies(entitlements: entitlements))
        #expect(!viewModel.isPro)

        let paywall = PaywallViewModel(entitlements: entitlements)
        await paywall.purchase()
        await viewModel.exportPDF(for: makeItem(), reminders: ReminderPreferences())

        #expect(viewModel.isPro)
        #expect(viewModel.exportedPDF != nil)
    }

    @Test("Only the extra reminder times are locked on the free plan")
    func settingsOffsetLocks() {
        let free = SettingsViewModel(entitlements: MockEntitlementService(isPro: false), notifications: MockNotificationScheduler())
        let pro = SettingsViewModel(entitlements: MockEntitlementService(isPro: true), notifications: MockNotificationScheduler())

        #expect(ReminderPreferences.availableOffsets.filter { free.isLocked(offset: $0) } == [30, 7, 1])
        #expect(!ReminderPreferences.availableOffsets.contains { pro.isLocked(offset: $0) })
    }

    @Test("Every Pro feature has paywall copy")
    func featureCopy() {
        for feature in ProFeature.allCases {
            #expect(!feature.title.isEmpty)
            #expect(!feature.detail.isEmpty)
            #expect(!feature.systemImage.isEmpty)
        }
    }
}
