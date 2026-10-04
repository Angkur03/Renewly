//
// ItemEditorViewModel.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation
import OSLog
import SwiftData

@Observable
@MainActor
final class ItemEditorViewModel {
    static let maxTitleLength = 80
    static let maxFieldLength = 120

    var category: ItemCategory
    var title: String
    var cost: Double
    var currencyCode: String
    var startDate: Date
    var expirationDate: Date
    var billingCycle: BillingCycle
    var serialNumber: String
    var retailer: String
    var cancellationURL: String
    var isNotificationEnabled: Bool
    var errorMessage: String?
    var isPaywallPresented = false

    private(set) var receiptPreviewData: Data?
    private(set) var isSaving = false

    let itemID: UUID

    @ObservationIgnored private var item: TrackedItem?
    @ObservationIgnored private var pendingReceiptData: Data?
    @ObservationIgnored private var shouldRemoveExistingReceipt = false
    @ObservationIgnored private var didApplyDefaultReminder = false
    @ObservationIgnored private let dependencies: AppDependencies
    @ObservationIgnored private let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly", category: "ItemEditor")

    init(item: TrackedItem?, defaultCurrency: String, dependencies: AppDependencies, now: Date = .now) {
        self.item = item
        self.dependencies = dependencies
        itemID = item?.id ?? UUID()
        category = item?.category ?? .subscription
        title = item?.title ?? ""
        cost = item?.cost ?? 0
        currencyCode = item?.currencyCode ?? defaultCurrency
        startDate = item?.startDate ?? now
        expirationDate = item?.expirationDate ?? Calendar.current.date(byAdding: .month, value: 1, to: now) ?? now
        billingCycle = item?.billingCycle ?? .monthly
        serialNumber = item?.serialNumber ?? ""
        retailer = item?.retailer ?? ""
        cancellationURL = item?.cancellationURL ?? ""
        isNotificationEnabled = item?.isNotificationEnabled ?? false
    }

    var isEditing: Bool { item != nil }

    var navigationTitle: String { isEditing ? "Edit Item" : "New Item" }

    var trimmedTitle: String { Self.sanitized(title, maxLength: Self.maxTitleLength) ?? "" }

    var isCancellationURLValid: Bool {
        guard let value = Self.sanitized(cancellationURL, maxLength: 2048) else { return true }
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased() else { return false }
        return ["http", "https"].contains(scheme) && url.host() != nil
    }

    var validationMessage: String? {
        if trimmedTitle.isEmpty { return "Enter a name." }
        if !cost.isFinite || cost < 0 { return "Enter a valid price." }
        if expirationDate < startDate { return "\(category.expirationLabel) must be after \(category.startLabel.lowercased())." }
        if category == .subscription && !isCancellationURLValid { return "Cancellation link must start with https://." }
        return nil
    }

    var canSave: Bool { validationMessage == nil && !isSaving }

    func loadExistingReceipt() async {
        guard pendingReceiptData == nil, !shouldRemoveExistingReceipt, let path = item?.receiptImagePath else { return }
        do {
            receiptPreviewData = try await dependencies.receipts.load(relativePath: path)
        } catch {
            errorMessage = error.userMessage
        }
    }

    func setReceipt(_ data: Data) {
        pendingReceiptData = data
        receiptPreviewData = data
        shouldRemoveExistingReceipt = false
    }

    func removeReceipt() {
        pendingReceiptData = nil
        receiptPreviewData = nil
        shouldRemoveExistingReceipt = item?.receiptImagePath != nil
    }

    /// New items start with reminders on whenever the plan's quota allows it.
    func applyDefaultReminder(activeAlertItemIDs: Set<UUID>) {
        guard !isEditing, !didApplyDefaultReminder else { return }
        didApplyDefaultReminder = true
        isNotificationEnabled = dependencies.notifications.canEnableAlerts(
            for: itemID,
            activeAlertItemIDs: activeAlertItemIDs,
            isPro: dependencies.entitlements.isPro
        )
    }

    func notificationToggleChanged(to isOn: Bool, activeAlertItemIDs: Set<UUID>) {
        guard isOn else { return }
        let allowed = dependencies.notifications.canEnableAlerts(
            for: itemID,
            activeAlertItemIDs: activeAlertItemIDs,
            isPro: dependencies.entitlements.isPro
        )
        if !allowed {
            isNotificationEnabled = false
            isPaywallPresented = true
        }
    }

    /// Returns `true` when the item was persisted and its reminders are in sync.
    func save(in context: ModelContext, activeAlertItemIDs: Set<UUID>) async -> Bool {
        guard canSave else { return false }
        isSaving = true
        defer { isSaving = false }

        if isNotificationEnabled {
            guard await verifyCanSchedule(activeAlertItemIDs: activeAlertItemIDs) else { return false }
        }

        let previousReceiptPath = item?.receiptImagePath
        let newReceiptPath: String?
        do {
            newReceiptPath = try await resolveReceiptPath(previous: previousReceiptPath)
        } catch {
            errorMessage = error.userMessage
            return false
        }

        let target = apply(to: item, receiptPath: newReceiptPath, in: context)
        do {
            try context.save()
        } catch {
            context.rollback()
            if newReceiptPath != previousReceiptPath, let newReceiptPath {
                await deleteReceiptQuietly(at: newReceiptPath)
            }
            errorMessage = "The item could not be saved. Please try again."
            return false
        }
        item = target
        pendingReceiptData = nil
        shouldRemoveExistingReceipt = false

        if let previousReceiptPath, previousReceiptPath != newReceiptPath {
            await deleteReceiptQuietly(at: previousReceiptPath)
        }

        return await syncNotifications(for: target, activeAlertItemIDs: activeAlertItemIDs, in: context)
    }

    private func verifyCanSchedule(activeAlertItemIDs: Set<UUID>) async -> Bool {
        guard dependencies.notifications.canEnableAlerts(
            for: itemID,
            activeAlertItemIDs: activeAlertItemIDs,
            isPro: dependencies.entitlements.isPro
        ) else {
            isNotificationEnabled = false
            isPaywallPresented = true
            return false
        }
        do {
            guard try await dependencies.notifications.requestAuthorization() else {
                errorMessage = NotificationError.notAuthorized.userMessage
                return false
            }
        } catch {
            errorMessage = error.userMessage
            return false
        }
        return true
    }

    private func resolveReceiptPath(previous: String?) async throws(ReceiptStorageError) -> String? {
        if let pendingReceiptData {
            return try await dependencies.receipts.save(pendingReceiptData)
        }
        return shouldRemoveExistingReceipt ? nil : previous
    }

    private func apply(to existing: TrackedItem?, receiptPath: String?, in context: ModelContext) -> TrackedItem {
        let target: TrackedItem
        if let existing {
            target = existing
        } else {
            target = TrackedItem(
                id: itemID,
                title: trimmedTitle,
                category: category,
                cost: cost,
                currencyCode: currencyCode,
                startDate: startDate,
                expirationDate: expirationDate
            )
            context.insert(target)
        }

        target.title = trimmedTitle
        target.category = category
        target.cost = cost
        target.currencyCode = currencyCode
        target.startDate = startDate
        target.expirationDate = expirationDate
        target.isNotificationEnabled = isNotificationEnabled
        target.receiptImagePath = receiptPath

        switch category {
        case .subscription:
            target.billingCycle = billingCycle
            target.cancellationURL = Self.sanitized(cancellationURL, maxLength: 2048)
            target.serialNumber = nil
            target.retailer = nil
        case .warranty:
            target.serialNumber = Self.sanitized(serialNumber, maxLength: Self.maxFieldLength)
            target.retailer = Self.sanitized(retailer, maxLength: Self.maxFieldLength)
            target.cancellationURL = nil
        }
        return target
    }

    private func syncNotifications(for target: TrackedItem, activeAlertItemIDs: Set<UUID>, in context: ModelContext) async -> Bool {
        guard target.isNotificationEnabled else {
            await dependencies.notifications.cancel(for: target.id)
            return true
        }
        do {
            try await dependencies.notifications.schedule(
                for: target.snapshot,
                activeAlertItemIDs: activeAlertItemIDs,
                isPro: dependencies.entitlements.isPro,
                deliverMissedReminder: true
            )
            return true
        } catch {
            target.isNotificationEnabled = false
            isNotificationEnabled = false
            do {
                try context.save()
            } catch {
                logger.error("Could not persist disabled alerts after scheduling failure.")
            }
            errorMessage = "Saved, but reminders are off. \(error.userMessage)"
            return false
        }
    }

    private func deleteReceiptQuietly(at path: String) async {
        do {
            try await dependencies.receipts.delete(relativePath: path)
        } catch {
            logger.error("Receipt cleanup failed: \(error.userMessage, privacy: .public)")
        }
    }

    static func sanitized(_ value: String, maxLength: Int) -> String? {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !$0.isNewline }
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxLength))
    }
}
