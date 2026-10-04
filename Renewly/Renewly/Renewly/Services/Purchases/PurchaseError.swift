//
// PurchaseError.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum PurchaseError: Error, Equatable, Sendable {
    case productUnavailable
    case verificationFailed
    case pending
    case purchaseFailed
    case restoreFailed

    var userMessage: String {
        switch self {
        case .productUnavailable: "Renewly Pro is not available right now. Please try again later."
        case .verificationFailed: "The purchase could not be verified."
        case .pending: "Your purchase is pending approval. Pro unlocks as soon as it completes."
        case .purchaseFailed: "The purchase could not be completed."
        case .restoreFailed: "Purchases could not be restored. Check your connection and try again."
        }
    }
}
