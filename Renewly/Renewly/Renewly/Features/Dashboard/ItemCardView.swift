//
// ItemCardView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftData
import SwiftUI

struct ItemCardView: View {
    let item: TrackedItem
    var now: Date = .now

    var body: some View {
        let snapshot = item.snapshot
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: item.category.systemImage)
                .font(.title3)
                .foregroundStyle(tint(for: item.category))
                .frame(width: 44, height: 44)
                .background(tint(for: item.category).opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .appFont(.headline)
                    .lineLimit(1)
                Text(subtitle)
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    expirationBadge(for: snapshot)
                    if snapshot.isInTrial() {
                        BadgeView("Trial", systemImage: "gift.fill", tint: .pink)
                    }
                    if item.isNotificationEnabled {
                        BadgeView("Alerts", systemImage: "bell.fill", tint: .indigo)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.cost, format: .currency(code: item.currencyCode))
                    .appFont(.headline)
                    .lineLimit(1)
                if item.category == .subscription {
                    Text(item.billingCycle.shortSuffix)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .cardSurface(cornerRadius: 20)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let date = item.expirationDate.formatted(date: .abbreviated, time: .omitted)
        switch item.category {
        case .subscription where item.isInTrial():
            return "Free trial · first charge \(date)"
        case .subscription:
            return "\(item.billingCycle.title) · renews \(date)"
        case .warranty:
            if let retailer = item.retailer, !retailer.isEmpty {
                return "\(retailer) · until \(date)"
            }
            return "Covered until \(date)"
        }
    }

    @ViewBuilder
    private func expirationBadge(for snapshot: ItemSnapshot) -> some View {
        let days = snapshot.daysUntilExpiration(from: now)
        if days < 0 {
            BadgeView(ExpiryText.badge(days: days), systemImage: "exclamationmark.triangle.fill", tint: .red)
        } else if days <= 1 {
            BadgeView(ExpiryText.badge(days: days), systemImage: "clock.badge.exclamationmark.fill", tint: .red)
        } else if snapshot.isExpiringSoon(now: now) {
            BadgeView(ExpiryText.badge(days: days), systemImage: "clock.fill", tint: .orange)
        } else {
            BadgeView(item.category.title, tint: tint(for: item.category))
        }
    }

    private func tint(for category: ItemCategory) -> Color {
        switch category {
        case .subscription: .accentColor
        case .warranty: .green
        }
    }
}

#Preview {
    let container = PreviewData.container(populated: false)
    let items = PreviewData.sampleItems()
    items.forEach { container.mainContext.insert($0) }
    return ZStack {
        AppBackground()
        ScrollView {
            VStack(spacing: 12) {
                ForEach(items) { item in
                    ItemCardView(item: item)
                }
            }
            .padding()
        }
    }
    .modelContainer(container)
}
