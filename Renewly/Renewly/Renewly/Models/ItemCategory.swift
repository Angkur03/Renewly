//
// ItemCategory.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum ItemCategory: String, CaseIterable, Identifiable, Sendable {
    case subscription
    case warranty

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subscription: String(localized: "Subscription")
        case .warranty: String(localized: "Warranty")
        }
    }

    var systemImage: String {
        switch self {
        case .subscription: "arrow.triangle.2.circlepath"
        case .warranty: "checkmark.shield.fill"
        }
    }

    var expirationLabel: String {
        switch self {
        case .subscription: String(localized: "Next renewal")
        case .warranty: String(localized: "Warranty expires")
        }
    }

    /// Lowercase field name for use inside a sentence, e.g. "Filled in price and purchase date".
    var startFieldName: String {
        switch self {
        case .subscription: String(localized: "start date", comment: "Field name inside a sentence")
        case .warranty: String(localized: "purchase date", comment: "Field name inside a sentence")
        }
    }

    var expirationFieldName: String {
        switch self {
        case .subscription: String(localized: "renewal date", comment: "Field name inside a sentence")
        case .warranty: String(localized: "expiry date", comment: "Field name inside a sentence")
        }
    }

    var startLabel: String {
        switch self {
        case .subscription: String(localized: "Started")
        case .warranty: String(localized: "Purchased")
        }
    }
}
