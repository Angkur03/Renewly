//
// WidgetSnapshot.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// The upcoming dates the app shares with its widgets. Widgets never open the database; the app writes this
/// summary whenever items change, and the widget recomputes "days left" for each day on its timeline.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    nonisolated enum Kind: String, Codable, Sendable {
        case subscription
        case warranty
        case trial
    }

    nonisolated struct Item: Codable, Equatable, Identifiable, Sendable {
        let id: UUID
        let title: String
        let kind: Kind
        /// Renewal, warranty end or trial end.
        let date: Date
    }

    static let currentFormatVersion = 1

    var formatVersion = Self.currentFormatVersion
    let generatedAt: Date
    /// Upcoming items, soonest first.
    let items: [Item]

    static let empty = WidgetSnapshot(generatedAt: .distantPast, items: [])

    /// Items still upcoming on `date`, soonest first.
    func upcoming(on date: Date, calendar: Calendar = .current) -> [Item] {
        let day = calendar.startOfDay(for: date)
        return items.filter { calendar.startOfDay(for: $0.date) >= day }
    }
}

nonisolated enum WidgetText {
    static func daysLeft(until date: Date, from now: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
    }

    /// e.g. "Renews tomorrow", "Trial ends in 3 days", "Expires today".
    static func relative(days: Int, kind: WidgetSnapshot.Kind) -> String {
        let verb = switch kind {
        case .subscription: "Renews"
        case .warranty: "Expires"
        case .trial: "Trial ends"
        }
        return switch days {
        case ...0: "\(verb) today"
        case 1: "\(verb) tomorrow"
        default: "\(verb) in \(days) days"
        }
    }

    /// e.g. "Today", "1d", "12d".
    static func compact(days: Int) -> String {
        days <= 0 ? "Today" : "\(days)d"
    }
}

/// `renewly://item/<uuid>` opens an item from a widget.
nonisolated enum WidgetDeepLink {
    static let scheme = "renewly"
    static let itemHost = "item"

    static func url(for itemID: UUID) -> URL? {
        URL(string: "\(scheme)://\(itemHost)/\(itemID.uuidString)")
    }

    static func itemID(from url: URL) -> UUID? {
        guard url.scheme == scheme, url.host() == itemHost else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}

nonisolated enum WidgetSnapshotError: Error, Equatable {
    case containerUnavailable
    case readFailed
    case writeFailed
    case unsupportedFormat
}

/// Reads and writes the snapshot in the App Group container shared by the app and its widgets.
nonisolated struct WidgetSnapshotStore: Sendable {
    static let appGroupID = "group.com.beleiveinAllahRenewly.Renewly"
    static let widgetKind = "RenewlyUpcomingWidget"
    private static let fileName = "widget-snapshot.json"

    let fileURL: URL?

    init(fileURL: URL?) {
        self.fileURL = fileURL
    }

    static var shared: WidgetSnapshotStore {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        return WidgetSnapshotStore(fileURL: container?.appending(path: fileName))
    }

    /// A missing file means the app has not written anything yet.
    func read() throws(WidgetSnapshotError) -> WidgetSnapshot {
        guard let fileURL else { throw .containerUnavailable }
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return .empty }
        let snapshot: WidgetSnapshot
        do {
            snapshot = try Self.decoder.decode(WidgetSnapshot.self, from: Data(contentsOf: fileURL))
        } catch {
            throw .readFailed
        }
        guard snapshot.formatVersion <= WidgetSnapshot.currentFormatVersion else { throw .unsupportedFormat }
        return snapshot
    }

    func write(_ snapshot: WidgetSnapshot) throws(WidgetSnapshotError) {
        guard let fileURL else { throw .containerUnavailable }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Self.encoder.encode(snapshot).write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            throw .writeFailed
        }
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
