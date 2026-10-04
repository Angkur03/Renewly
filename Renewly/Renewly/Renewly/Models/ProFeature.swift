//
// ProFeature.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// Everything Renewly Pro unlocks. Tracking items, receipts, search and themes stay free.
nonisolated enum ProFeature: String, CaseIterable, Identifiable, Sendable {
    case unlimitedReminders
    case extraReminders
    case insights
    case pdfExport

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unlimitedReminders: "Unlimited reminders"
        case .extraReminders: "Extra reminder times"
        case .insights: "Spending insights"
        case .pdfExport: "PDF export"
        }
    }

    var detail: String {
        switch self {
        case .unlimitedReminders:
            "Alerts for every subscription and warranty, not just \(NotificationManager.freeAlertLimit)."
        case .extraReminders:
            "Add 30, 3 and 1 day alerts on top of the 7-day reminder."
        case .insights:
            "Monthly and yearly costs, a 12-month forecast and where your money goes."
        case .pdfExport:
            "Save any item with its receipt or warranty card as a PDF to print or share."
        }
    }

    var systemImage: String {
        switch self {
        case .unlimitedReminders: "bell.badge.fill"
        case .extraReminders: "bell.and.waves.left.and.right.fill"
        case .insights: "chart.pie.fill"
        case .pdfExport: "doc.richtext.fill"
        }
    }
}
