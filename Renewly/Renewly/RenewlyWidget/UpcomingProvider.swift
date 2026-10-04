//
// UpcomingProvider.swift
// RenewlyWidget
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import OSLog
import WidgetKit

struct UpcomingEntry: TimelineEntry {
    enum State: Equatable {
        case ready
        /// The App Group could not be read, e.g. before the app's first launch after install.
        case unavailable
    }

    let date: Date
    let items: [WidgetSnapshot.Item]
    var state: State = .ready

    static func sample(now: Date = .now, calendar: Calendar = .current) -> UpcomingEntry {
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: now) ?? now
        }
        return UpcomingEntry(date: now, items: [
            .init(id: UUID(), title: "YouTube Premium", kind: .trial, date: day(1)),
            .init(id: UUID(), title: "Spotify Duo", kind: .subscription, date: day(4)),
            .init(id: UUID(), title: "AirPods Pro", kind: .warranty, date: day(12)),
            .init(id: UUID(), title: "Netflix Premium", kind: .subscription, date: day(18)),
            .init(id: UUID(), title: "Xbox Game Pass", kind: .subscription, date: day(26)),
            .init(id: UUID(), title: "MacBook Pro 14\"", kind: .warranty, date: day(60))
        ])
    }
}

struct UpcomingProvider: TimelineProvider {
    /// One entry per midnight keeps "days left" correct for a week even if the app is never opened.
    static let daysAhead = 7

    var store: WidgetSnapshotStore = .shared
    var calendar: Calendar = .current

    func placeholder(in context: Context) -> UpcomingEntry {
        .sample(calendar: calendar)
    }

    func getSnapshot(in context: Context, completion: @escaping (UpcomingEntry) -> Void) {
        let entry = entries(now: .now)[0]
        if context.isPreview && entry.items.isEmpty {
            completion(.sample(calendar: calendar))
        } else {
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpcomingEntry>) -> Void) {
        completion(Timeline(entries: entries(now: .now), policy: .atEnd))
    }

    /// Always returns at least one entry, starting at `now`.
    func entries(now: Date) -> [UpcomingEntry] {
        let snapshot: WidgetSnapshot
        do {
            snapshot = try store.read()
        } catch {
            Self.logger.error("Widget snapshot unavailable: \(String(describing: error))")
            return [UpcomingEntry(date: now, items: [], state: .unavailable)]
        }
        let today = calendar.startOfDay(for: now)
        let midnights = (1...Self.daysAhead).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        return ([now] + midnights).map { date in
            UpcomingEntry(date: date, items: snapshot.upcoming(on: date, calendar: calendar))
        }
    }

    private static let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly.RenewlyWidget", category: "Timeline")
}
