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
    var showsInsightsHint = false
    var isInsightsLocked = false

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 18) {
                if showsInsightsHint {
                    HStack {
                        Text("Overview")
                            .appFont(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Spacer()
                        if isInsightsLocked {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                                .accessibilityLabel("Pro")
                        }
                        Label("Insights", systemImage: "chevron.right")
                            .labelStyle(TrailingIconLabelStyle())
                            .appFont(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.bottom, -6)
                }
                HStack(alignment: .top, spacing: 16) {
                    metric(
                        title: "Monthly burn",
                        value: summary.monthlyBurn,
                        caption: ExpiryText.count(summary.subscriptionCount, "subscription"),
                        systemImage: "flame.fill",
                        tint: .orange
                    )
                    Divider()
                        .frame(height: 64)
                    metric(
                        title: "Protected",
                        value: summary.protectedCapital,
                        caption: ExpiryText.count(summary.activeWarrantyCount, "active warranty", plural: "active warranties"),
                        systemImage: "checkmark.shield.fill",
                        tint: .green
                    )
                }

                if let nextUp = summary.nextUp {
                    nextUpRow(nextUp)
                }

                if summary.excludedItemCount > 0 {
                    Label(
                        summary.excludedItemCount == 1
                            ? "1 item in another currency is not included"
                            : "\(summary.excludedItemCount) items in other currencies are not included",
                        systemImage: "info.circle"
                    )
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func nextUpRow(_ nextUp: DashboardSummary.NextUp) -> some View {
        let isUrgent = nextUp.daysLeft <= 3
        return HStack(spacing: 10) {
            Image(systemName: isUrgent ? "bell.badge.fill" : "calendar")
                .foregroundStyle(isUrgent ? Color.orange : Color.accentColor)
                .frame(width: 28, height: 28)
                .background((isUrgent ? Color.orange : Color.accentColor).opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text("Next up")
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                Text(nextUp.title)
                    .appFont(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(ExpiryText.relative(days: nextUp.daysLeft, category: nextUp.category))
                .appFont(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(isUrgent ? Color.orange : Color.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .chipSurface(isSelected: false)
        .accessibilityElement(children: .combine)
    }

    private func metric(title: String, value: Double, caption: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .appFont(.subheadline)
                .foregroundStyle(tint)
            Text(value, format: .currency(code: summary.currencyCode))
                .appFont(.title2)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(caption)
                .appFont(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.title
            configuration.icon
                .imageScale(.small)
        }
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
                activeWarrantyCount: 1,
                excludedItemCount: 1,
                nextUp: .init(title: "Netflix", category: .subscription, daysLeft: 2)
            )
        )
        .padding()
    }
}
