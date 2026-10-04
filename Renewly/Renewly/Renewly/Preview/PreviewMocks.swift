//
// PreviewMocks.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class MockEntitlementService: EntitlementProviding {
    static let samplePlans = [
        ProPlan(kind: .monthly, displayPrice: "$4.99", price: 4.99, pricePerMonthText: nil, freeTrialDays: 7),
        ProPlan(kind: .yearly, displayPrice: "$19.99", price: 19.99, pricePerMonthText: "$1.66", freeTrialDays: 7)
    ]

    private(set) var isPro: Bool
    private(set) var isProcessing = false
    private(set) var activeSubscription: ActiveSubscription?
    let plans: [ProPlan]
    @ObservationIgnored private let purchaseError: PurchaseError?

    init(
        isPro: Bool = false,
        plans: [ProPlan] = MockEntitlementService.samplePlans,
        activeSubscription: ActiveSubscription? = nil,
        purchaseError: PurchaseError? = nil
    ) {
        self.isPro = isPro
        self.plans = plans
        self.activeSubscription = activeSubscription
            ?? (isPro ? ActiveSubscription(kind: .yearly, expirationDate: .now.addingTimeInterval(86_400 * 5), isInFreeTrial: true) : nil)
        self.purchaseError = purchaseError
    }

    func loadProducts() async {}
    func refreshEntitlements() async {}
    func observeTransactionUpdates() async {}

    func purchase(_ plan: ProPlanKind) async throws(PurchaseError) -> Bool {
        if let purchaseError { throw purchaseError }
        isPro = true
        activeSubscription = ActiveSubscription(kind: plan, expirationDate: .now.addingTimeInterval(86_400 * 7), isInFreeTrial: true)
        return true
    }

    func restorePurchases() async throws(PurchaseError) {
        if let purchaseError { throw purchaseError }
    }
}

nonisolated struct MockNotificationScheduler: NotificationScheduling {
    var isAuthorized = true

    func authorizationStatus() async -> NotificationAuthorization {
        isAuthorized ? .authorized : .denied
    }

    func requestAuthorization() async throws(NotificationError) -> Bool {
        isAuthorized
    }

    func canEnableAlerts(for itemID: UUID, activeAlertItemIDs: Set<UUID>, isPro: Bool) -> Bool {
        isPro || activeAlertItemIDs.subtracting([itemID]).count < NotificationManager.freeAlertLimit
    }

    func schedule(
        for item: ItemSnapshot,
        activeAlertItemIDs: Set<UUID>,
        isPro: Bool,
        deliverMissedReminder: Bool
    ) async throws(NotificationError) {
        guard canEnableAlerts(for: item.id, activeAlertItemIDs: activeAlertItemIDs, isPro: isPro) else {
            throw .quotaExceeded(limit: NotificationManager.freeAlertLimit)
        }
        guard isAuthorized else { throw .notAuthorized }
    }

    func cancel(for itemID: UUID) async {}

    func sendTestAlert(after seconds: Int) async throws(NotificationError) {
        guard isAuthorized else { throw .notAuthorized }
    }

    func pendingAlertCount() async -> Int { 0 }
}

actor InMemoryReceiptStore: ReceiptImageStoring {
    private var storage: [String: Data] = [:]

    func save(_ imageData: Data) throws(ReceiptStorageError) -> String {
        let path = "Receipts/\(UUID().uuidString).jpg"
        storage[path] = imageData
        return path
    }

    func load(relativePath: String) throws(ReceiptStorageError) -> Data {
        guard let data = storage[relativePath] else { throw .readFailed }
        return data
    }

    func delete(relativePath: String) throws(ReceiptStorageError) {
        storage[relativePath] = nil
    }
}

@MainActor
enum PreviewData {
    static func dependencies(
        isPro: Bool = false,
        notificationsAuthorized: Bool = true,
        purchaseError: PurchaseError? = nil
    ) -> AppDependencies {
        AppDependencies(
            entitlements: MockEntitlementService(isPro: isPro, purchaseError: purchaseError),
            notifications: MockNotificationScheduler(isAuthorized: notificationsAuthorized),
            receipts: InMemoryReceiptStore(),
            pdfExporter: ReceiptPDFExporter()
        )
    }

    static func container(populated: Bool) -> ModelContainer {
        let schema = Schema([TrackedItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Preview container failed: \(error)")
        }
        if populated {
            sampleItems().forEach { container.mainContext.insert($0) }
        }
        return container
    }

    static func sampleItems(now: Date = .now) -> [TrackedItem] {
        let calendar = Calendar.current
        func days(_ value: Int) -> Date {
            calendar.date(byAdding: .day, value: value, to: now) ?? now
        }
        let currency = CurrencyDefaults.deviceCurrencyCode
        return [
            TrackedItem(
                title: "Netflix Premium",
                category: .subscription,
                cost: 22.99,
                currencyCode: currency,
                startDate: days(-200),
                expirationDate: days(5),
                isNotificationEnabled: true,
                billingCycle: .monthly,
                cancellationURL: "https://www.netflix.com/cancelplan"
            ),
            TrackedItem(
                title: "iCloud+ 2TB",
                category: .subscription,
                cost: 119.88,
                currencyCode: currency,
                startDate: days(-120),
                expirationDate: days(245),
                billingCycle: .yearly
            ),
            TrackedItem(
                title: "MacBook Pro 14\"",
                category: .warranty,
                cost: 2499,
                currencyCode: currency,
                startDate: days(-300),
                expirationDate: days(430),
                isNotificationEnabled: true,
                serialNumber: "C02XK1ABCD12",
                retailer: "Apple Store"
            ),
            TrackedItem(
                title: "Sony WH-1000XM5",
                category: .warranty,
                cost: 399,
                currencyCode: currency,
                startDate: days(-355),
                expirationDate: days(10),
                retailer: "Best Buy"
            ),
            TrackedItem(
                title: "Spotify Family",
                category: .subscription,
                cost: 50,
                currencyCode: "EUR",
                startDate: days(-60),
                expirationDate: days(-2),
                billingCycle: .quarterly
            )
        ]
    }
}
