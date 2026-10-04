//
// WidgetSnapshotTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import os
import Testing
@testable import Renewly

@Suite("Widget snapshot")
struct WidgetSnapshotTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 12)) ?? .distantPast
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: now) ?? now
    }

    private func item(_ title: String, _ category: ItemCategory, in days: Int, trial: Bool = false) -> ItemSnapshot {
        ItemSnapshot(
            id: UUID(), title: title, category: category, cost: 10, currencyCode: "USD",
            expirationDate: day(days), billingCycle: .monthly, isNotificationEnabled: false,
            trialEndDate: trial ? day(days) : nil
        )
    }

    private func temporaryStore() -> WidgetSnapshotStore {
        WidgetSnapshotStore(fileURL: FileManager.default.temporaryDirectory
            .appending(path: "WidgetSnapshotTests-\(UUID().uuidString)")
            .appending(path: "snapshot.json"))
    }

    // MARK: Builder

    @Test("Only upcoming items are shared, soonest first, with their kind")
    func builderSortsAndFilters() {
        let snapshot = WidgetSnapshotBuilder.make(from: [
            item("AirPods", .warranty, in: 12),
            item("Hulu", .subscription, in: -1),
            item("YouTube", .subscription, in: 2, trial: true),
            item("Netflix", .subscription, in: 0)
        ], now: now, calendar: calendar)

        #expect(snapshot.items.map(\.title) == ["Netflix", "YouTube", "AirPods"])
        #expect(snapshot.items.map(\.kind) == [.subscription, .trial, .warranty])
    }

    @Test("The snapshot is capped")
    func builderCaps() {
        let items = (0..<30).map { item("Item \($0)", .subscription, in: $0) }
        #expect(WidgetSnapshotBuilder.make(from: items, now: now, calendar: calendar).items.count == WidgetSnapshotBuilder.maxItems)
    }

    @Test("Items drop off once their day has passed")
    func upcomingOnLaterDay() {
        let snapshot = WidgetSnapshotBuilder.make(from: [
            item("Netflix", .subscription, in: 1), item("Spotify", .subscription, in: 3)
        ], now: now, calendar: calendar)

        #expect(snapshot.upcoming(on: day(1), calendar: calendar).map(\.title) == ["Netflix", "Spotify"])
        #expect(snapshot.upcoming(on: day(2), calendar: calendar).map(\.title) == ["Spotify"])
        #expect(snapshot.upcoming(on: day(4), calendar: calendar).isEmpty)
    }

    // MARK: Text & links

    @Test("Widget wording", arguments: [
        (0, WidgetSnapshot.Kind.subscription, "Renews today"),
        (1, .warranty, "Expires tomorrow"),
        (5, .trial, "Trial ends in 5 days")
    ])
    func relativeText(days: Int, kind: WidgetSnapshot.Kind, expected: String) {
        #expect(WidgetText.relative(days: days, kind: kind) == expected)
    }

    @Test func compactText() {
        #expect(WidgetText.compact(days: 0) == "Today")
        #expect(WidgetText.compact(days: 9) == "9d")
        #expect(WidgetText.daysLeft(until: day(3), from: now, calendar: calendar) == 3)
    }

    @Test("Deep links round-trip and reject other URLs")
    func deepLinks() throws {
        let id = UUID()
        let url = try #require(WidgetDeepLink.url(for: id))
        #expect(WidgetDeepLink.itemID(from: url) == id)
        #expect(WidgetDeepLink.itemID(from: try #require(URL(string: "https://renewly.app/item/\(id)"))) == nil)
        #expect(WidgetDeepLink.itemID(from: try #require(URL(string: "renewly://settings/\(id)"))) == nil)
        #expect(WidgetDeepLink.itemID(from: try #require(URL(string: "renewly://item/not-a-uuid"))) == nil)
    }

    // MARK: Store

    @Test("The store round-trips and treats a missing file as empty")
    func storeRoundTrip() throws {
        let store = temporaryStore()
        defer { removeDirectory(of: store) }
        #expect(try store.read() == .empty)

        let snapshot = WidgetSnapshotBuilder.make(from: [item("Netflix", .subscription, in: 4)], now: now, calendar: calendar)
        try store.write(snapshot)
        #expect(try store.read() == snapshot)
    }

    @Test("A missing App Group and unreadable files are reported")
    func storeErrors() throws {
        #expect(throws: WidgetSnapshotError.containerUnavailable) {
            try WidgetSnapshotStore(fileURL: nil).read()
        }

        let store = temporaryStore()
        defer { removeDirectory(of: store) }
        let url = try #require(store.fileURL)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)
        #expect(throws: WidgetSnapshotError.readFailed) {
            try store.read()
        }
    }

    // MARK: Publisher

    @Test("Widgets reload only when the shown items change")
    func publisherSkipsUnchanged() async throws {
        let store = temporaryStore()
        defer { removeDirectory(of: store) }
        let reloads = OSAllocatedUnfairLock(initialState: 0)
        let publisher = LiveWidgetPublisher(store: store, reloadTimelines: { reloads.withLock { $0 += 1 } })
        let items = [item("Netflix", .subscription, in: 4)]

        await publisher.publish(WidgetSnapshotBuilder.make(from: items, now: now, calendar: calendar))
        await publisher.publish(WidgetSnapshotBuilder.make(from: items, now: day(0).addingTimeInterval(60), calendar: calendar))
        #expect(reloads.withLock { $0 } == 1)

        await publisher.publish(WidgetSnapshotBuilder.make(from: items + [item("Spotify", .subscription, in: 6)], now: now, calendar: calendar))
        #expect(reloads.withLock { $0 } == 2)
        #expect(try store.read().items.count == 2)
    }

    private func removeDirectory(of store: WidgetSnapshotStore) {
        guard let url = store.fileURL?.deletingLastPathComponent() else { return }
        do {
            if FileManager.default.fileExists(atPath: url.path()) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            Issue.record("Could not clean up: \(error)")
        }
    }
}
