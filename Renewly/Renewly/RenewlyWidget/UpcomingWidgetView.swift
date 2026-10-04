//
// UpcomingWidgetView.swift
// RenewlyWidget
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI
import WidgetKit

extension WidgetSnapshot.Kind {
    var systemImage: String {
        switch self {
        case .subscription: "arrow.triangle.2.circlepath"
        case .warranty: "checkmark.shield.fill"
        case .trial: "gift.fill"
        }
    }

    var tint: Color {
        switch self {
        case .subscription: .blue
        case .warranty: .green
        case .trial: .pink
        }
    }
}

struct UpcomingWidgetView: View {
    let entry: UpcomingEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            InlineView(entry: entry)
        case .accessoryCircular:
            CircularView(entry: entry)
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .systemSmall:
            SmallView(entry: entry)
        case .systemLarge:
            ListView(entry: entry, limit: 6)
        default:
            ListView(entry: entry, limit: 3)
        }
    }
}

// MARK: Home screen

private struct SmallView: View {
    let entry: UpcomingEntry

    var body: some View {
        if let item = entry.items.first {
            let days = WidgetText.daysLeft(until: item.date, from: entry.date)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Next up")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    KindIcon(kind: item.kind, size: 26)
                }
                Spacer(minLength: 0)
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(WidgetText.relative(days: days, kind: item.kind))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(days <= 3 ? Color.orange : item.kind.tint)
                    .lineLimit(2)
                Text(item.date, format: .dateTime.day().month(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .widgetURL(WidgetDeepLink.url(for: item.id))
        } else {
            EmptyStateView(state: entry.state)
        }
    }
}

private struct ListView: View {
    let entry: UpcomingEntry
    let limit: Int

    var body: some View {
        if entry.items.isEmpty {
            EmptyStateView(state: entry.state)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Next up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text("Renewly")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                ForEach(entry.items.prefix(limit)) { item in
                    if let url = WidgetDeepLink.url(for: item.id) {
                        Link(destination: url) {
                            ItemRow(item: item, now: entry.date)
                        }
                    } else {
                        ItemRow(item: item, now: entry.date)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct ItemRow: View {
    let item: WidgetSnapshot.Item
    let now: Date

    var body: some View {
        let days = WidgetText.daysLeft(until: item.date, from: now)
        HStack(spacing: 10) {
            KindIcon(kind: item.kind, size: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(WidgetText.relative(days: days, kind: item.kind))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(WidgetText.compact(days: days))
                .font(.caption.weight(.bold))
                .foregroundStyle(days <= 3 ? Color.orange : item.kind.tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background((days <= 3 ? Color.orange : item.kind.tint).opacity(0.15), in: Capsule())
        }
    }
}

private struct KindIcon: View {
    let kind: WidgetSnapshot.Kind
    let size: CGFloat

    var body: some View {
        Image(systemName: kind.systemImage)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(kind.tint)
            .frame(width: size, height: size)
            .background(kind.tint.opacity(0.15), in: Circle())
            .accessibilityHidden(true)
    }
}

private struct EmptyStateView: View {
    let state: UpcomingEntry.State

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: state == .ready ? "checkmark.seal.fill" : "arrow.clockwise.circle.fill")
                .font(.title2)
                .foregroundStyle(state == .ready ? Color.green : Color.secondary)
            Text(state == .ready ? "All clear" : "Open Renewly")
                .font(.headline)
            Text(state == .ready ? "Nothing coming up." : "Open the app to load your items.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: Lock screen

private struct RectangularView: View {
    let entry: UpcomingEntry

    var body: some View {
        if let item = entry.items.first {
            let days = WidgetText.daysLeft(until: item.date, from: entry.date)
            VStack(alignment: .leading, spacing: 1) {
                Label("Next up", systemImage: item.kind.systemImage)
                    .font(.caption2.weight(.semibold))
                    .widgetAccentable()
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(WidgetText.relative(days: days, kind: item.kind))
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetURL(WidgetDeepLink.url(for: item.id))
        } else {
            Label("Nothing coming up", systemImage: "checkmark.seal")
                .font(.caption)
        }
    }
}

private struct InlineView: View {
    let entry: UpcomingEntry

    var body: some View {
        if let item = entry.items.first {
            let days = WidgetText.daysLeft(until: item.date, from: entry.date)
            Label("\(item.title) · \(WidgetText.compact(days: days))", systemImage: item.kind.systemImage)
                .widgetURL(WidgetDeepLink.url(for: item.id))
        } else {
            Label("Nothing coming up", systemImage: "checkmark.seal")
        }
    }
}

private struct CircularView: View {
    let entry: UpcomingEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let item = entry.items.first {
                let days = WidgetText.daysLeft(until: item.date, from: entry.date)
                VStack(spacing: 0) {
                    Image(systemName: item.kind.systemImage)
                        .font(.caption2)
                        .widgetAccentable()
                    Text(days <= 0 ? "Today" : "\(days)")
                        .font(days <= 0 ? .caption.weight(.bold) : .title3.weight(.bold))
                        .minimumScaleFactor(0.6)
                    if days > 0 {
                        Text(days == 1 ? "day" : "days")
                            .font(.system(size: 9))
                    }
                }
                .widgetURL(WidgetDeepLink.url(for: item.id))
            } else {
                Image(systemName: "checkmark.seal")
                    .font(.title3)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
