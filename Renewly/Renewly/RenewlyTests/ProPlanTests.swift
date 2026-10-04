//
// ProPlanTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@Suite("Pro subscription plans")
struct ProPlanTests {
    @Test("Yearly at 19.99 saves 66% against 4.99 monthly")
    func yearlySavings() {
        #expect(ProPlan.savingsPercent(monthlyPrice: 4.99, yearlyPrice: 19.99) == 66)
    }

    @Test("No savings badge when yearly is not cheaper")
    func noSavings() {
        #expect(ProPlan.savingsPercent(monthlyPrice: 1, yearlyPrice: 12) == nil)
        #expect(ProPlan.savingsPercent(monthlyPrice: 0, yearlyPrice: 5) == nil)
    }

    @Test("Trial period converts to days", arguments: [
        (1, ProPlan.TrialUnit.week, 7),
        (7, ProPlan.TrialUnit.day, 7),
        (2, ProPlan.TrialUnit.week, 14)
    ])
    func trialDays(value: Int, unit: ProPlan.TrialUnit, expected: Int) {
        #expect(ProPlan.days(periodValue: value, unit: unit) == expected)
    }

    @Test("Product identifiers round-trip to plan kinds")
    func productIDs() {
        for kind in ProPlanKind.allCases {
            #expect(ProPlanKind(productID: kind.productID) == kind)
        }
        #expect(ProPlanKind(productID: "com.example.other.monthly") == nil)
    }

    @Test("Price with period")
    func priceWithPeriod() {
        let plan = ProPlan(kind: .yearly, displayPrice: "$19.99", price: 19.99, pricePerMonthText: "$1.66", freeTrialDays: 7)
        #expect(plan.priceWithPeriod == "$19.99/year")
    }

    @MainActor
    @Test("Paywall defaults to yearly and advertises the trial")
    func paywallCopy() {
        let viewModel = PaywallViewModel(entitlements: MockEntitlementService())
        #expect(viewModel.selectedPlan == .yearly)
        #expect(viewModel.purchaseButtonTitle == "Start 7-day free trial")
        #expect(viewModel.finePrint.hasPrefix("Free for 7 days, then $19.99/year."))
    }

    @MainActor
    @Test("Paywall without trial eligibility shows the plain price")
    func paywallNoTrial() {
        let viewModel = PaywallViewModel(entitlements: MockEntitlementService(plans: [
            ProPlan(kind: .monthly, displayPrice: "$4.99", price: 4.99, pricePerMonthText: nil, freeTrialDays: nil)
        ]))
        viewModel.selectedPlan = .monthly
        #expect(viewModel.purchaseButtonTitle == "Subscribe for $4.99/month")
    }

    @MainActor
    @Test("Purchasing unlocks Pro with a trial subscription")
    func purchase() async {
        let entitlements = MockEntitlementService()
        let viewModel = PaywallViewModel(entitlements: entitlements)
        viewModel.selectedPlan = .monthly
        await viewModel.purchase()
        #expect(entitlements.isPro)
        #expect(entitlements.activeSubscription?.kind == .monthly)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test("Purchase failures surface a message")
    func purchaseFailure() async {
        let viewModel = PaywallViewModel(entitlements: MockEntitlementService(purchaseError: .purchaseFailed))
        await viewModel.purchase()
        #expect(viewModel.errorMessage == PurchaseError.purchaseFailed.userMessage)
    }
}
