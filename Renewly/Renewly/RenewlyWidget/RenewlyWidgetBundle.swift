//
// RenewlyWidgetBundle.swift
// RenewlyWidget
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI
import WidgetKit

@main
struct RenewlyWidgetBundle: WidgetBundle {
    var body: some Widget {
        UpcomingWidget()
    }
}

struct UpcomingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshotStore.widgetKind, provider: UpcomingProvider()) { entry in
            UpcomingWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .configurationDisplayName("Next up")
        .description("Upcoming renewals, free trials ending and warranty expiries.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryRectangular, .accessoryCircular, .accessoryInline
        ])
    }
}

#Preview("Small", as: .systemSmall) {
    UpcomingWidget()
} timeline: {
    UpcomingEntry.sample()
    UpcomingEntry(date: .now, items: [])
}

#Preview("Medium", as: .systemMedium) {
    UpcomingWidget()
} timeline: {
    UpcomingEntry.sample()
    UpcomingEntry(date: .now, items: [], state: .unavailable)
}

#Preview("Large", as: .systemLarge) {
    UpcomingWidget()
} timeline: {
    UpcomingEntry.sample()
}

#Preview("Lock screen", as: .accessoryRectangular) {
    UpcomingWidget()
} timeline: {
    UpcomingEntry.sample()
}
