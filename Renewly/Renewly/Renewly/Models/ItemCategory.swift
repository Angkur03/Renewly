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
        case .subscription: "Subscription"
        case .warranty: "Warranty"
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
        case .subscription: "Next renewal"
        case .warranty: "Warranty expires"
        }
    }

    var startLabel: String {
        switch self {
        case .subscription: "Started"
        case .warranty: "Purchased"
        }
    }
}
