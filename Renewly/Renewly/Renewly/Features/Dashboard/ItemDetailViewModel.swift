//
// ItemDetailViewModel.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation
import SwiftData
import UIKit

nonisolated struct ExportedPDF: Identifiable, Hashable, Sendable {
    let url: URL
    var id: URL { url }
}

@Observable
@MainActor
final class ItemDetailViewModel {
    private(set) var receiptImage: UIImage?
    private(set) var receiptData: Data?
    private(set) var receiptLoadFailed = false
    private(set) var isExporting = false
    private(set) var isDeleting = false
    var exportedPDF: ExportedPDF?
    var paywallFeature: ProFeature?
    var errorMessage: String?

    @ObservationIgnored private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func loadReceipt(at path: String?) async {
        receiptImage = nil
        receiptData = nil
        receiptLoadFailed = false
        guard let path else { return }
        do {
            let data = try await dependencies.receipts.load(relativePath: path)
            receiptData = data
            receiptImage = UIImage(data: data)
            receiptLoadFailed = receiptImage == nil
        } catch {
            receiptLoadFailed = true
        }
    }

    var isPro: Bool { dependencies.entitlements.isPro }
    var entitlements: any EntitlementProviding { dependencies.entitlements }

    /// Free users are shown the paywall instead of exporting.
    func exportPDF(for item: TrackedItem, reminders: ReminderPreferences) async {
        guard isPro else {
            paywallFeature = .pdfExport
            return
        }
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        let document = Self.makeDocument(for: item, imageData: receiptData, reminders: reminders)
        do {
            exportedPDF = ExportedPDF(url: try await dependencies.pdfExporter.export(document))
        } catch {
            errorMessage = error.userMessage
        }
    }

    /// Returns `true` once the item is gone, so the caller can leave the screen.
    func delete(_ item: TrackedItem, in context: ModelContext) async -> Bool {
        guard !isDeleting else { return false }
        isDeleting = true
        defer { isDeleting = false }

        guard await ItemDeletionService(dependencies: dependencies).delete(item, in: context) else {
            errorMessage = "The item could not be deleted. Please try again."
            return false
        }
        return true
    }

    static func reminderSummary(for item: TrackedItem, reminders: ReminderPreferences) -> String {
        guard reminders.isEnabled else { return "Off in Settings" }
        return item.isNotificationEnabled ? reminders.scheduleDescription : "Off"
    }

    static func makeDocument(
        for item: TrackedItem,
        imageData: Data?,
        reminders: ReminderPreferences = ReminderPreferences(),
        now: Date = .now
    ) -> ReceiptDocument {
        let currency = FloatingPointFormatStyle<Double>.Currency(code: item.currencyCode)
        let longDate = Date.FormatStyle(date: .long, time: .omitted)
        var lines: [ReceiptDocument.Line] = []

        switch item.category {
        case .subscription:
            lines.append(.init(label: "Price", value: "\(item.cost.formatted(currency)) \(item.billingCycle.title.lowercased())"))
            lines.append(.init(label: "Monthly equivalent", value: item.billingCycle.monthlyEquivalent(of: item.cost).formatted(currency)))
        case .warranty:
            lines.append(.init(label: "Purchase price", value: item.cost.formatted(currency)))
            if let retailer = item.retailer {
                lines.append(.init(label: "Retailer", value: retailer))
            }
            if let serial = item.serialNumber {
                lines.append(.init(label: "Serial number", value: serial))
            }
        }
        lines.append(.init(label: item.category.startLabel, value: item.startDate.formatted(longDate)))
        let isTrial = item.isInTrial()
        let expirationLabel = isTrial ? "Trial ends (first charge)" : item.category.expirationLabel
        lines.append(.init(label: expirationLabel, value: item.expirationDate.formatted(longDate)))

        let days = item.snapshot.daysUntilExpiration(from: now)
        lines.append(.init(label: "Status", value: ExpiryText.relative(days: days, category: item.category, isTrial: isTrial)))
        lines.append(.init(label: "Reminders", value: reminderSummary(for: item, reminders: reminders)))
        if let url = item.validCancellationURL {
            lines.append(.init(label: "Manage / cancel", value: url.absoluteString))
        }

        return ReceiptDocument(
            title: item.title,
            categoryTitle: item.category.title,
            headline: item.cost.formatted(currency),
            lines: lines,
            attachmentTitle: item.category == .warranty ? "Warranty card / receipt" : "Receipt",
            imageData: imageData,
            generatedAt: now
        )
    }
}
