//
// ItemDetailViewModel.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation
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
    var exportedPDF: ExportedPDF?
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

    func exportPDF(for item: TrackedItem, reminders: ReminderPreferences) async {
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
        lines.append(.init(label: item.category.expirationLabel, value: item.expirationDate.formatted(longDate)))

        let days = item.snapshot.daysUntilExpiration(from: now)
        let status = switch days {
        case ..<0: "Expired \(-days) day(s) ago"
        case 0: "Due today"
        default: "\(days) day(s) remaining"
        }
        lines.append(.init(label: "Status", value: status))
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
