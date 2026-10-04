//
// PaywallView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Observation
import SwiftUI

@Observable
@MainActor
final class PaywallViewModel {
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")

    var selectedPlan: ProPlanKind = .yearly
    var errorMessage: String?

    @ObservationIgnored let entitlements: any EntitlementProviding

    init(entitlements: any EntitlementProviding) {
        self.entitlements = entitlements
    }

    var isPro: Bool { entitlements.isPro }
    var isProcessing: Bool { entitlements.isProcessing }
    var plans: [ProPlan] { entitlements.plans }
    var isLoadingPlans: Bool { plans.isEmpty }

    var selected: ProPlan? {
        plans.first { $0.kind == selectedPlan }
    }

    var yearlySavingsPercent: Int? {
        guard let monthly = plans.first(where: { $0.kind == .monthly }),
              let yearly = plans.first(where: { $0.kind == .yearly }) else {
            return nil
        }
        return ProPlan.savingsPercent(monthlyPrice: monthly.price, yearlyPrice: yearly.price)
    }

    var purchaseButtonTitle: String {
        guard let selected else { return "Continue" }
        if let days = selected.freeTrialDays {
            return "Start \(days)-day free trial"
        }
        return "Subscribe for \(selected.priceWithPeriod)"
    }

    var finePrint: String {
        guard let selected else {
            return "Subscriptions auto-renew until cancelled. Cancel anytime in Settings."
        }
        let renewal = "Auto-renews at \(selected.priceWithPeriod) until cancelled. Cancel anytime in Settings at least 24 hours before the end of the current period."
        if let days = selected.freeTrialDays {
            return "Free for \(days) days, then \(selected.priceWithPeriod). \(renewal)"
        }
        return renewal
    }

    func loadPlansIfNeeded() async {
        guard plans.isEmpty else { return }
        await entitlements.loadProducts()
    }

    func purchase() async {
        do {
            _ = try await entitlements.purchase(selectedPlan)
        } catch {
            errorMessage = error.userMessage
        }
    }

    func restore() async {
        do {
            try await entitlements.restorePurchases()
            if !isPro {
                errorMessage = "No active Renewly Pro subscription was found for this Apple Account."
            }
        } catch {
            errorMessage = error.userMessage
        }
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PaywallViewModel
    @State private var purchaseTrigger = 0

    init(entitlements: any EntitlementProviding) {
        _viewModel = State(initialValue: PaywallViewModel(entitlements: entitlements))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            feature("bell.badge.fill", title: "Unlimited reminders", detail: "Alerts for every subscription and warranty, not just \(NotificationManager.freeAlertLimit).")
                            feature("bell.and.waves.left.and.right.fill", title: "Every reminder", detail: "30, 7, 3 and 1 day alerts on all your items, at 9:00 AM.")
                            feature("lock.shield.fill", title: "Still private", detail: "Your data stays on this device. No account needed.")
                        }
                    }
                    planPicker
                    actions
                }
                .padding()
            }
            .background(AppBackground())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await viewModel.loadPlansIfNeeded() }
            .onChange(of: viewModel.isPro) { _, isPro in
                if isPro { dismiss() }
            }
            .rigidHaptic(trigger: purchaseTrigger)
            .rigidHaptic(trigger: viewModel.selectedPlan)
            .errorAlert(message: $viewModel.errorMessage)
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundStyle(.yellow.gradient)
                .padding(20)
                .cardSurface(cornerRadius: 46)
            Text("Renewly Pro")
                .appFont(.largeTitle)
            Text("Never miss a renewal or a warranty claim again.")
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private var planPicker: some View {
        if viewModel.isLoadingPlans {
            ProgressView("Loading plans…")
                .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            VStack(spacing: 12) {
                ForEach(viewModel.plans.reversed()) { plan in
                    planCard(plan)
                }
            }
        }
    }

    private func planCard(_ plan: ProPlan) -> some View {
        let isSelected = plan.kind == viewModel.selectedPlan
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return Button {
            withAnimation(.snappy) { viewModel.selectedPlan = plan.kind }
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.kind.title)
                            .appFont(.headline)
                        if plan.kind == .yearly, let savings = viewModel.yearlySavingsPercent {
                            BadgeView("Best value · Save \(savings)%", tint: .green)
                        }
                    }
                    if let days = plan.freeTrialDays {
                        Text("\(days)-day free trial, then \(plan.priceWithPeriod)")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Billed every \(plan.kind.periodNoun)")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.displayPrice)
                        .appFont(.title3)
                    Text(plan.pricePerMonthText.map { "\($0)/mo" } ?? "per month")
                        .appFont(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .cardSurface(cornerRadius: 20)
            .overlay {
                if isSelected {
                    shape.strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                purchaseTrigger += 1
                Task { await viewModel.purchase() }
            } label: {
                Group {
                    if viewModel.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(viewModel.purchaseButtonTitle)
                            .appFont(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isProcessing || viewModel.selected == nil)

            Text(viewModel.finePrint)
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Restore Purchases") {
                    Task { await viewModel.restore() }
                }
                .disabled(viewModel.isProcessing)
                if let termsURL = PaywallViewModel.termsURL {
                    Link("Terms of Use", destination: termsURL)
                }
            }
            .appFont(.footnote)
        }
    }

    private func feature(_ systemImage: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appFont(.headline)
                Text(detail)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Trial eligible") {
    PaywallView(entitlements: MockEntitlementService())
}

#Preview("No trial") {
    PaywallView(entitlements: MockEntitlementService(plans: [
        ProPlan(kind: .monthly, displayPrice: "$4.99", price: 4.99, pricePerMonthText: nil, freeTrialDays: nil),
        ProPlan(kind: .yearly, displayPrice: "$19.99", price: 19.99, pricePerMonthText: "$1.66", freeTrialDays: nil)
    ]))
}

#Preview("Loading") {
    PaywallView(entitlements: MockEntitlementService(plans: []))
}

#Preview("Purchase error") {
    PaywallView(entitlements: MockEntitlementService(purchaseError: .purchaseFailed))
}
