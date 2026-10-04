//
// WidgetSnapshotSync.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftData
import SwiftUI

/// Republishes the widget snapshot whenever an item that widgets show is added, edited, rolled over or deleted.
struct WidgetSnapshotSync: View {
    let publisher: any WidgetPublishing

    @Query private var items: [TrackedItem]

    var body: some View {
        let snapshot = WidgetSnapshotBuilder.make(from: items.map(\.snapshot), now: .now)
        Color.clear
            .accessibilityHidden(true)
            .task(id: snapshot.items) {
                await publisher.publish(snapshot)
            }
    }
}
