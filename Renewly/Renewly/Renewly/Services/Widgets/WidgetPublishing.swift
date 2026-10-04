//
// WidgetPublishing.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import OSLog
import WidgetKit

nonisolated enum WidgetSnapshotBuilder {
    /// Enough to keep the large widget full for days after the app was last opened.
    static let maxItems = 12

    static func make(from items: [ItemSnapshot], now: Date, calendar: Calendar = .current) -> WidgetSnapshot {
        let upcoming = items
            .filter { $0.daysUntilExpiration(from: now, calendar: calendar) >= 0 }
            .sorted { ($0.expirationDate, $0.title) < ($1.expirationDate, $1.title) }
            .prefix(maxItems)
            .map { item in
                WidgetSnapshot.Item(id: item.id, title: item.title, kind: kind(of: item, calendar: calendar), date: item.expirationDate)
            }
        return WidgetSnapshot(generatedAt: now, items: Array(upcoming))
    }

    static func kind(of item: ItemSnapshot, calendar: Calendar) -> WidgetSnapshot.Kind {
        if item.isInTrial(calendar: calendar) { return .trial }
        return item.category == .subscription ? .subscription : .warranty
    }
}

nonisolated protocol WidgetPublishing: Sendable {
    func publish(_ snapshot: WidgetSnapshot) async
}

/// Writes the snapshot to the App Group and asks WidgetKit to refresh, skipping both when nothing changed.
nonisolated struct LiveWidgetPublisher: WidgetPublishing {
    private let store: WidgetSnapshotStore
    private let reloadTimelines: @Sendable () -> Void

    init(
        store: WidgetSnapshotStore = .shared,
        reloadTimelines: @escaping @Sendable () -> Void = {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshotStore.widgetKind)
        }
    ) {
        self.store = store
        self.reloadTimelines = reloadTimelines
    }

    @concurrent
    func publish(_ snapshot: WidgetSnapshot) async {
        do {
            if try store.read().items == snapshot.items { return }
        } catch {
            Self.logger.notice("Widget snapshot unreadable (\(String(describing: error))); rewriting it.")
        }
        do {
            try store.write(snapshot)
        } catch {
            Self.logger.error("Could not write the widget snapshot: \(String(describing: error))")
            return
        }
        reloadTimelines()
    }

    private static let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly", category: "Widgets")
}
