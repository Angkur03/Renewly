//
// StoreKitEntitlementService.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation
import OSLog
import StoreKit

@Observable
@MainActor
final class StoreKitEntitlementService: EntitlementProviding {
    private(set) var hasPurchasedPro = false
    private(set) var isProcessing = false
    private(set) var plans: [ProPlan] = []
    private(set) var activeSubscription: ActiveSubscription?

    @ObservationIgnored private var products: [ProPlanKind: Product] = [:]
    @ObservationIgnored private let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly", category: "Purchases")

    #if DEBUG
    var isDebugProOverrideEnabled = UserDefaults.standard.bool(forKey: AppStorageKey.debugProOverride) {
        didSet { UserDefaults.standard.set(isDebugProOverrideEnabled, forKey: AppStorageKey.debugProOverride) }
    }

    var isPro: Bool { hasPurchasedPro || isDebugProOverrideEnabled }
    #else
    var isPro: Bool { hasPurchasedPro }
    #endif

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProPlanKind.allCases.map(\.productID))
            var byKind: [ProPlanKind: Product] = [:]
            for product in loaded {
                if let kind = ProPlanKind(productID: product.id) {
                    byKind[kind] = product
                }
            }
            products = byKind
            await rebuildPlans()
        } catch {
            logger.error("Loading products failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func refreshEntitlements() async {
        var best: (transaction: Transaction, kind: ProPlanKind)?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil,
                  let kind = ProPlanKind(productID: transaction.productID) else {
                continue
            }
            if let current = best,
               (current.transaction.expirationDate ?? .distantFuture) >= (transaction.expirationDate ?? .distantFuture) {
                continue
            }
            best = (transaction, kind)
        }

        if let best {
            activeSubscription = ActiveSubscription(
                kind: best.kind,
                expirationDate: best.transaction.expirationDate,
                isInFreeTrial: Self.isIntroductoryOffer(best.transaction)
            )
        } else {
            activeSubscription = nil
        }
        hasPurchasedPro = best != nil
        await rebuildPlans()
    }

    func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
            await refreshEntitlements()
        }
    }

    func purchase(_ plan: ProPlanKind) async throws(PurchaseError) -> Bool {
        if products[plan] == nil {
            await loadProducts()
        }
        guard let product = products[plan] else { throw .productUnavailable }

        isProcessing = true
        defer { isProcessing = false }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription, privacy: .public)")
            throw .purchaseFailed
        }

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw .verificationFailed }
            await transaction.finish()
            await refreshEntitlements()
            return true
        case .pending:
            throw .pending
        case .userCancelled:
            return false
        @unknown default:
            throw .purchaseFailed
        }
    }

    func restorePurchases() async throws(PurchaseError) {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await AppStore.sync()
        } catch {
            logger.error("Restore failed: \(error.localizedDescription, privacy: .public)")
            throw .restoreFailed
        }
        await refreshEntitlements()
    }

    private func rebuildPlans() async {
        var built: [ProPlan] = []
        for kind in ProPlanKind.allCases {
            guard let product = products[kind] else { continue }
            built.append(ProPlan(
                kind: kind,
                displayPrice: product.displayPrice,
                price: product.price,
                pricePerMonthText: kind == .yearly ? (product.price / 12).formatted(product.priceFormatStyle) : nil,
                freeTrialDays: await Self.eligibleFreeTrialDays(for: product)
            ))
        }
        plans = built
    }

    private static func eligibleFreeTrialDays(for product: Product) async -> Int? {
        guard let subscription = product.subscription,
              let offer = subscription.introductoryOffer,
              offer.paymentMode == .freeTrial,
              await subscription.isEligibleForIntroOffer else {
            return nil
        }
        let unit: ProPlan.TrialUnit = switch offer.period.unit {
        case .day: .day
        case .week: .week
        case .month: .month
        case .year: .year
        @unknown default: .day
        }
        return ProPlan.days(periodValue: offer.period.value, unit: unit)
    }

    private static func isIntroductoryOffer(_ transaction: Transaction) -> Bool {
        if #available(iOS 17.2, *) {
            return transaction.offer?.type == .introductory
        }
        return transaction.offerType == .introductory
    }
}
