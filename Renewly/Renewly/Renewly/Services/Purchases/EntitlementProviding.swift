//
// EntitlementProviding.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation

@MainActor
protocol EntitlementProviding: AnyObject, Observable {
    var isPro: Bool { get }
    /// Available plans sorted monthly then yearly; empty until products load.
    var plans: [ProPlan] { get }
    var activeSubscription: ActiveSubscription? { get }
    var isProcessing: Bool { get }

    func loadProducts() async
    func refreshEntitlements() async
    /// Runs until the calling task is cancelled; attach it to a view's `.task`.
    func observeTransactionUpdates() async
    /// Returns `false` when the user cancels the purchase sheet.
    func purchase(_ plan: ProPlanKind) async throws(PurchaseError) -> Bool
    func restorePurchases() async throws(PurchaseError)
}
