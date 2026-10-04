//
// InsightsView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Charts
import SwiftData
import SwiftUI

struct InsightsView: View {
    private enum Period: String, CaseIterable, Identifiable {
        case month = "Per month"
        case year = "Per year"
        var id: String { rawValue }
    }

    let entitlements: any EntitlementProviding

    @Query private var items: [TrackedItem]
    @AppStorage(AppStorageKey.primaryCurrency) private var primaryCurrency = CurrencyDefaults.deviceCurrencyCode
    @Environment(\.scenePhase) private var scenePhase

    @State private var period: Period = .month
    @State private var selectedMonth: Date?
    @State private var now = Date.now
    @State private var isPaywallPresented = false

    private static let sliceColors: [Color] = [.accentColor, .purple, .pink, .orange, .teal]

    var body: some View {
        let insights = SpendingInsights.make(from: items.map(\.snapshot), currencyCode: primaryCurrency, now: now)
        let isLocked = !entitlements.isPro && !insights.isEmpty

        ScrollView {
            content(insights)
                .blur(radius: isLocked ? 10 : 0)
                .allowsHitTesting(!isLocked)
                .accessibilityHidden(isLocked)
        }
        .scrollDisabled(isLocked)
        .overlay {
            if isLocked {
                lockedCard
                    .padding(24)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.snappy, value: isLocked)
        .background(AppBackground())
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(entitlements: entitlements, highlighting: .insights)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { now = .now }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            now = .now
        }
    }

    private var lockedCard: some View {
        GlassCard(cornerRadius: 28, padding: 24) {
            VStack(spacing: 14) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor.gradient)
                    .padding(16)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
                Text("Unlock Spending Insights")
                    .appFont(.title2)
                    .multilineTextAlignment(.center)
                Text(ProFeature.insights.detail)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    isPaywallPresented = true
                } label: {
                    Label("Try Pro free", systemImage: "crown.fill")
                        .appFont(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func content(_ insights: SpendingInsights) -> some View {
        Group {
            if insights.isEmpty {
                ContentUnavailableView(
                    "No insights yet",
                    systemImage: "chart.pie",
                    description: Text(items.isEmpty
                        ? "Add subscriptions or warranties to see where your money goes."
                        : "None of your items use \(primaryCurrency). Change the main currency in Settings.")
                )
                .padding(.top, 80)
            } else {
                VStack(spacing: 16) {
                    heroCard(insights)
                    if insights.subscriptionCount > 0 {
                        upcomingCard(insights)
                        projectionCard(insights)
                        sharesCard(insights)
                    }
                    if insights.warranties.activeCount + insights.warranties.expiredCount > 0 {
                        warrantyCard(insights.warranties, currency: insights.currencyCode)
                    }
                    if insights.excludedItemCount > 0 {
                        Label(
                            insights.excludedItemCount == 1
                                ? "1 item in another currency is not included."
                                : "\(insights.excludedItemCount) items in other currencies are not included.",
                            systemImage: "info.circle"
                        )
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
        }
    }

    // MARK: Hero

    private func heroCard(_ insights: SpendingInsights) -> some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Period", selection: $period.animation(.snappy)) {
                    ForEach(Period.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscriptions cost you")
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(period == .month ? insights.monthlyTotal : insights.yearlyTotal, format: currency(insights))
                        .appFont(.largeTitle)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(period == .month ? "every month" : "every year")
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    statPill(
                        title: "Subscriptions",
                        value: Text(insights.subscriptionCount, format: .number),
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                    statPill(
                        title: "Per day",
                        value: Text(insights.dailyAverage, format: currency(insights)),
                        systemImage: "sun.max.fill"
                    )
                }
            }
        }
    }

    private func statPill(title: String, value: Text, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .appFont(.caption2)
                    .foregroundStyle(.secondary)
                value
                    .appFont(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .chipSurface(isSelected: false)
        .accessibilityElement(children: .combine)
    }

    // MARK: Next 30 days

    private func upcomingCard(_ insights: SpendingInsights) -> some View {
        let visible = insights.upcomingCharges.prefix(5)
        let hiddenCount = insights.upcomingCharges.count - visible.count

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader("Next \(SpendingInsights.upcomingWindowDays) days", systemImage: "calendar.badge.clock") {
                    Text(insights.upcomingTotal, format: currency(insights))
                        .appFont(.headline)
                        .contentTransition(.numericText())
                }

                if visible.isEmpty {
                    Text("No renewals in the next \(SpendingInsights.upcomingWindowDays) days.")
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(visible)) { charge in
                        chargeRow(charge, currency: insights.currencyCode)
                    }
                    if hiddenCount > 0 {
                        Text("+ \(ExpiryText.count(hiddenCount, "more renewal"))")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func chargeRow(_ charge: RenewalCharge, currency: String) -> some View {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: charge.date)).day ?? 0
        return HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(charge.date, format: .dateTime.day())
                    .appFont(.headline)
                Text(charge.date, format: .dateTime.month(.abbreviated))
                    .appFont(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 44, height: 44)
            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(charge.title)
                    .appFont(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(ExpiryText.relative(days: days, category: .subscription))
                    .appFont(.caption)
                    .foregroundStyle(days <= 3 ? Color.orange : Color.secondary)
            }
            Spacer(minLength: 8)
            Text(charge.amount, format: .currency(code: currency))
                .appFont(.subheadline)
                .fontWeight(.semibold)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Next 12 months

    private func projectionCard(_ insights: SpendingInsights) -> some View {
        let selected = selectedMonth.flatMap { date in
            insights.projection.first { Calendar.current.isDate($0.month, equalTo: date, toGranularity: .month) }
        }

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader("Next \(SpendingInsights.projectionMonths) months", systemImage: "chart.bar.fill") {
                    Text(insights.projectionTotal, format: currency(insights))
                        .appFont(.headline)
                }

                Group {
                    if let selected {
                        Text("\(selected.month.formatted(.dateTime.month(.wide).year())): \(selected.amount.formatted(currency(insights)))")
                    } else if let peak = insights.peakMonth, peak.amount > 0 {
                        Text("Busiest month: \(peak.month.formatted(.dateTime.month(.wide))) (\(peak.amount.formatted(currency(insights))))")
                    }
                }
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)

                Chart(insights.projection) { month in
                    BarMark(
                        x: .value("Month", month.month, unit: .month),
                        y: .value("Amount", month.amount)
                    )
                    .cornerRadius(5)
                    .foregroundStyle(barStyle(for: month, selected: selected, peak: insights.peakMonth))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartXSelection(value: $selectedMonth)
                .frame(height: 180)
                .accessibilityLabel("Projected subscription spend for the next 12 months")
            }
        }
    }

    private func barStyle(for month: MonthlySpend, selected: MonthlySpend?, peak: MonthlySpend?) -> AnyShapeStyle {
        if let selected {
            return selected.month == month.month ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color.accentColor.opacity(0.25))
        }
        if month.month == peak?.month, month.amount > 0 {
            return AnyShapeStyle(Color.orange.gradient)
        }
        return AnyShapeStyle(Color.accentColor.gradient)
    }

    // MARK: Breakdown

    private func sharesCard(_ insights: SpendingInsights) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader("Where it goes", systemImage: "chart.pie.fill") { EmptyView() }

                HStack(alignment: .center, spacing: 18) {
                    Chart(Array(insights.shares.enumerated()), id: \.element.id) { index, share in
                        SectorMark(
                            angle: .value("Monthly cost", share.monthlyAmount),
                            innerRadius: .ratio(0.62),
                            angularInset: 2
                        )
                        .cornerRadius(4)
                        .foregroundStyle(color(forSlice: index, isOther: share.isOther))
                    }
                    .chartLegend(.hidden)
                    .frame(width: 120, height: 120)
                    .overlay {
                        VStack(spacing: 0) {
                            Text(insights.monthlyTotal, format: currency(insights))
                                .appFont(.subheadline)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            Text("/mo")
                                .appFont(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 70)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(insights.shares.enumerated()), id: \.element.id) { index, share in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(color(forSlice: index, isOther: share.isOther))
                                    .frame(width: 9, height: 9)
                                Text(share.title)
                                    .appFont(.caption)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text(share.fraction, format: .percent.precision(.fractionLength(0)))
                                    .appFont(.caption)
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
    }

    private func color(forSlice index: Int, isOther: Bool) -> Color {
        isOther ? .gray : Self.sliceColors[index % Self.sliceColors.count]
    }

    // MARK: Warranties

    private func warrantyCard(_ coverage: WarrantyCoverage, currency: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader("Warranty coverage", systemImage: "checkmark.shield.fill") {
                    Text(coverage.protectedValue, format: .currency(code: currency))
                        .appFont(.headline)
                        .foregroundStyle(.green)
                }
                HStack(spacing: 10) {
                    coverageTile(value: coverage.activeCount, title: "Active", tint: .green)
                    coverageTile(value: coverage.expiringSoonCount, title: "Ending in \(SpendingInsights.warrantyExpiringWindowDays)d", tint: .orange)
                    coverageTile(value: coverage.expiredCount, title: "Expired", tint: .secondary)
                }
            }
        }
    }

    private func coverageTile(value: Int, title: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .appFont(.title2)
                .foregroundStyle(tint)
                .contentTransition(.numericText())
            Text(title)
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Helpers

    private func cardHeader<Trailing: View>(_ title: String, systemImage: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Label(title, systemImage: systemImage)
                .appFont(.headline)
            Spacer(minLength: 8)
            trailing()
        }
    }

    private func currency(_ insights: SpendingInsights) -> FloatingPointFormatStyle<Double>.Currency {
        .currency(code: insights.currencyCode)
    }
}

#Preview("Pro") {
    NavigationStack {
        InsightsView(entitlements: MockEntitlementService(isPro: true))
    }
    .modelContainer(PreviewData.container(populated: true))
}

#Preview("Free (locked)") {
    NavigationStack {
        InsightsView(entitlements: MockEntitlementService(isPro: false))
    }
    .modelContainer(PreviewData.container(populated: true))
}

#Preview("Empty") {
    NavigationStack {
        InsightsView(entitlements: MockEntitlementService(isPro: true))
    }
    .modelContainer(PreviewData.container(populated: false))
}

#Preview("Other currency only") {
    let container = PreviewData.container(populated: false)
    container.mainContext.insert(TrackedItem(
        title: "Deezer", category: .subscription, cost: 11.99, currencyCode: "EUR",
        startDate: .now, expirationDate: .now.addingTimeInterval(86_400 * 10)
    ))
    return NavigationStack {
        InsightsView(entitlements: MockEntitlementService(isPro: true))
    }
    .modelContainer(container)
    .defaultAppStorage(UserDefaults(suiteName: "insights-preview") ?? .standard)
}
