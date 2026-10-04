//
// SummaryHeaderCard.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

struct SummaryHeaderCard: View {
    let summary: DashboardSummary

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    metric(
                        title: "Monthly burn",
                        value: summary.monthlyBurn,
                        caption: "\(summary.subscriptionCount) subscriptions",
                        systemImage: "flame.fill",
                        tint: .orange
                    )
                    Divider()
                        .frame(height: 64)
                    metric(
                        title: "Protected",
                        value: summary.protectedCapital,
                        caption: "\(summary.activeWarrantyCount) active warranties",
                        systemImage: "checkmark.shield.fill",
                        tint: .green
                    )
                }

                if summary.excludedItemCount > 0 {
                    Label(
                        "\(summary.excludedItemCount) item(s) in other currencies are not included",
                        systemImage: "info.circle"
                    )
                    .vaultFont(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func metric(title: String, value: Double, caption: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .vaultFont(.subheadline)
                .foregroundStyle(tint)
            Text(value, format: .currency(code: summary.currencyCode))
                .vaultFont(.title2)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(caption)
                .vaultFont(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        AppBackground()
        SummaryHeaderCard(
            summary: DashboardSummary(
                currencyCode: "USD",
                monthlyBurn: 32.98,
                protectedCapital: 2898,
                subscriptionCount: 2,
                activeWarrantyCount: 2,
                excludedItemCount: 1
            )
        )
        .padding()
    }
}
