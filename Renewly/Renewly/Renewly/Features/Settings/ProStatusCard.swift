//
// ProStatusCard.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

struct ProStatusCard: View {
    let isPro: Bool
    let subscription: ActiveSubscription?
    let onUpgrade: () -> Void
    let onManage: () -> Void

    var body: some View {
        GlassCard(cornerRadius: 22) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: isPro ? "crown.fill" : "sparkles")
                    .font(.title2)
                    .foregroundStyle(isPro ? .yellow : .accentColor)
                    .frame(width: 48, height: 48)
                    .background((isPro ? Color.yellow : Color.accentColor).opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .appFont(.headline)
                        if subscription?.isInFreeTrial == true {
                            BadgeView("Trial", tint: .green)
                        }
                    }
                    Text(detail)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 4)
                if isPro {
                    Button("Manage", action: onManage)
                        .buttonStyle(.bordered)
                        .appFont(.subheadline)
                } else {
                    Button("Try free", action: onUpgrade)
                        .buttonStyle(.borderedProminent)
                        .appFont(.subheadline)
                }
            }
        }
    }

    private var title: String {
        guard isPro else { return "Renewly Free" }
        guard let subscription else { return "Renewly Pro" }
        return "Pro · \(subscription.kind.title)"
    }

    private var detail: String {
        guard isPro else {
            return "7-day reminders for up to \(NotificationManager.freeAlertLimit) items. Try Pro free for 7 days: unlimited reminders, insights and PDF export."
        }
        guard let date = subscription?.expirationDate else {
            return "Unlimited reminders, insights and PDF export are unlocked."
        }
        let formatted = date.formatted(date: .abbreviated, time: .omitted)
        return subscription?.isInFreeTrial == true
            ? "Free trial ends \(formatted). Cancel before then to avoid being charged."
            : "Current period ends \(formatted)."
    }
}

#Preview {
    VStack(spacing: 16) {
        ProStatusCard(isPro: false, subscription: nil, onUpgrade: {}, onManage: {})
        ProStatusCard(
            isPro: true,
            subscription: ActiveSubscription(kind: .yearly, expirationDate: .now.addingTimeInterval(86_400 * 5), isInFreeTrial: true),
            onUpgrade: {},
            onManage: {}
        )
        ProStatusCard(
            isPro: true,
            subscription: ActiveSubscription(kind: .monthly, expirationDate: .now.addingTimeInterval(86_400 * 20), isInFreeTrial: false),
            onUpgrade: {},
            onManage: {}
        )
    }
    .padding()
    .background(AppBackground())
}
