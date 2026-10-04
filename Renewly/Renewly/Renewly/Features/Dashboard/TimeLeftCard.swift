//
// TimeLeftCard.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftData
import SwiftUI

struct TimeLeftCard: View {
    let item: TrackedItem
    let now: Date

    private var isTrial: Bool { item.isInTrial() }

    var body: some View {
        let progress = TimeLeftProgress.make(
            category: item.category,
            billingCycle: item.billingCycle,
            startDate: item.startDate,
            expirationDate: item.expirationDate,
            now: now,
            isTrial: isTrial
        )
        let tint = tint(for: progress)

        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Label(
                        ExpiryText.relative(days: progress.daysLeft, category: item.category, isTrial: isTrial),
                        systemImage: symbol(for: progress)
                    )
                        .appFont(.headline)
                        .foregroundStyle(tint)
                    Spacer(minLength: 8)
                    Text(item.expirationDate, format: .dateTime.day().month(.abbreviated).year())
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ProgressBar(fraction: progress.remainingFraction, tint: tint)

                Text(caption(for: progress))
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func caption(for progress: TimeLeftProgress) -> String {
        if progress.daysLeft < 0 {
            return item.category == .warranty
                ? "Coverage has ended. Keep the receipt in case the retailer offers goodwill repairs."
                : "This period has ended."
        }
        if isTrial {
            let price = item.cost.formatted(.currency(code: item.currencyCode))
            return "Free until then. You'll be charged \(price) unless you cancel before it ends."
        }
        let period = item.category == .subscription ? "this billing period" : "the warranty"
        guard progress.totalDays > 0 else { return "Ends today." }
        return "\(ExpiryText.count(max(progress.daysLeft, 0), "day")) left of \(progress.totalDays) in \(period)"
    }

    private func symbol(for progress: TimeLeftProgress) -> String {
        if progress.daysLeft < 0 { return "exclamationmark.triangle.fill" }
        if progress.daysLeft <= 3 { return "bell.badge.fill" }
        if isTrial { return "gift.fill" }
        return item.category == .subscription ? "arrow.triangle.2.circlepath" : "checkmark.shield.fill"
    }

    private func tint(for progress: TimeLeftProgress) -> Color {
        switch progress.daysLeft {
        case ..<0: .red
        case 0...3: .red
        case 4..<ItemSnapshot.expiringSoonThresholdDays: .orange
        default: item.category == .subscription ? .accentColor : .green
        }
    }
}

private struct ProgressBar: View {
    let fraction: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15))
                Capsule()
                    .fill(tint.gradient)
                    .frame(width: max(fraction > 0 ? 8 : 0, proxy.size.width * fraction))
            }
        }
        .frame(height: 8)
        .animation(.snappy, value: fraction)
        .accessibilityHidden(true)
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
                    TimeLeftCard(item: item, now: .now)
                }
            }
            .padding()
        }
    }
    .modelContainer(container)
}
