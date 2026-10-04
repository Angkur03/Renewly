//
// RenewlyIntents.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import AppIntents
import Foundation
import SwiftData

nonisolated enum RenewlyIntentError: Error, CustomLocalizedStringResourceConvertible {
    case storeUnavailable
    case itemNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .storeUnavailable: "Renewly couldn't read your items. Open the app and try again."
        case .itemNotFound: "That item is no longer in Renewly."
        }
    }
}

/// Reads items for App Intents from the same store the app uses.
@MainActor
enum IntentDataSource {
    static func items() throws(RenewlyIntentError) -> [TrackedItem] {
        let context = SharedModelContainer.shared.container.mainContext
        RenewalRolloverService().rollForward(in: context)
        do {
            return try context.fetch(FetchDescriptor<TrackedItem>(sortBy: [SortDescriptor(\.expirationDate)]))
        } catch {
            throw .storeUnavailable
        }
    }

    static var primaryCurrency: String {
        UserDefaults.standard.string(forKey: AppStorageKey.primaryCurrency) ?? CurrencyDefaults.deviceCurrencyCode
    }
}

// MARK: Entity

nonisolated struct ItemEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Item" }
    static var defaultQuery: ItemEntityQuery { ItemEntityQuery() }

    let id: UUID
    let title: String
    let subtitle: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }

    init(id: UUID, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }

    init(_ item: ItemSnapshot, now: Date = .now, calendar: Calendar = .current) {
        let days = max(0, item.daysUntilExpiration(from: now, calendar: calendar))
        let timing = item.isExpired(now: now)
            ? "Expired"
            : WidgetText.relative(days: days, kind: WidgetSnapshotBuilder.kind(of: item, calendar: calendar))
        self.init(id: item.id, title: item.title, subtitle: "\(item.category.title) · \(timing)")
    }
}

nonisolated struct ItemEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ItemEntity] {
        let wanted = Set(identifiers)
        return try IntentDataSource.items().filter { wanted.contains($0.id) }.map { ItemEntity($0.snapshot) }
    }

    @MainActor
    func entities(matching string: String) async throws -> [ItemEntity] {
        let needle = ServiceCatalog.normalized(string)
        return try IntentDataSource.items()
            .filter { needle.isEmpty || ServiceCatalog.normalized($0.title).contains(needle) }
            .map { ItemEntity($0.snapshot) }
    }

    /// Upcoming items first, so Siri's parameter suggestions favour what matters now.
    @MainActor
    func suggestedEntities() async throws -> [ItemEntity] {
        let now = Date.now
        let snapshots = try IntentDataSource.items().map(\.snapshot)
        let upcoming = snapshots.filter { !$0.isExpired(now: now) }
        let expired = snapshots.filter { $0.isExpired(now: now) }
        return (upcoming + expired).map { ItemEntity($0, now: now) }
    }
}

// MARK: Intents

struct UpcomingRenewalsIntent: AppIntent {
    static var title: LocalizedStringResource { "What's Coming Up" }
    static var description: IntentDescription {
        IntentDescription("Lists subscriptions renewing, free trials ending and warranties expiring soon.")
    }

    @Parameter(title: "Days ahead", default: 7, inclusiveRange: (1, 365))
    var days: Int

    static var parameterSummary: some ParameterSummary {
        Summary("What's coming up in the next \(\.$days) days")
    }

    init() {}

    init(days: Int) {
        self.days = days
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[ItemEntity]> & ProvidesDialog {
        let now = Date.now
        let snapshots = try IntentDataSource.items().map(\.snapshot)
        let due = IntentSummaries.upcoming(snapshots, within: days, now: now)
        return .result(
            value: due.map { ItemEntity($0, now: now) },
            dialog: IntentDialog(stringLiteral: IntentSummaries.upcomingDialog(snapshots, within: days, now: now))
        )
    }
}

struct MonthlySpendIntent: AppIntent {
    static var title: LocalizedStringResource { "Monthly Subscription Spend" }
    static var description: IntentDescription {
        IntentDescription("Tells you how much your subscriptions cost per month in your primary currency.")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let currency = IntentDataSource.primaryCurrency
        let snapshots = try IntentDataSource.items().map(\.snapshot)
        let summary = DashboardSummary.make(from: snapshots, currencyCode: currency, now: .now)
        return .result(
            value: summary.monthlyBurn,
            dialog: IntentDialog(stringLiteral: IntentSummaries.spendDialog(snapshots, currencyCode: currency, now: .now))
        )
    }
}

nonisolated enum ItemKindAppEnum: String, AppEnum {
    case subscription
    case warranty

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Item Type" }
    static var caseDisplayRepresentations: [ItemKindAppEnum: DisplayRepresentation] {
        [
            .subscription: DisplayRepresentation(title: "Subscription", image: .init(systemName: "arrow.triangle.2.circlepath")),
            .warranty: DisplayRepresentation(title: "Warranty", image: .init(systemName: "checkmark.shield"))
        ]
    }

    var category: ItemCategory {
        switch self {
        case .subscription: .subscription
        case .warranty: .warranty
        }
    }
}

struct AddItemIntent: AppIntent {
    static var title: LocalizedStringResource { "Add Item" }
    static var description: IntentDescription {
        IntentDescription("Opens Renewly ready to add a new subscription or warranty.")
    }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Type", default: .subscription)
    var kind: ItemKindAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Add a \(\.$kind)")
    }

    init() {}

    init(kind: ItemKindAppEnum) {
        self.kind = kind
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationRouter.shared.requestNewItem(kind.category)
        return .result()
    }
}

struct OpenItemIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Item" }
    static var description: IntentDescription {
        IntentDescription("Opens a subscription or warranty in Renewly.")
    }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Item")
    var item: ItemEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$item)")
    }

    init() {}

    init(item: ItemEntity) {
        self.item = item
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard try IntentDataSource.items().contains(where: { $0.id == item.id }) else {
            throw RenewlyIntentError.itemNotFound
        }
        NotificationRouter.shared.open(itemID: item.id)
        return .result()
    }
}

// MARK: Siri phrases

nonisolated struct RenewlyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: UpcomingRenewalsIntent(),
            phrases: [
                "What's coming up in \(.applicationName)",
                "What renews soon in \(.applicationName)",
                "What's due in \(.applicationName)"
            ],
            shortTitle: "Coming Up",
            systemImageName: "calendar.badge.clock"
        )
        AppShortcut(
            intent: MonthlySpendIntent(),
            phrases: [
                "How much do I spend in \(.applicationName)",
                "What's my monthly spend in \(.applicationName)"
            ],
            shortTitle: "Monthly Spend",
            systemImageName: "flame"
        )
        AppShortcut(
            intent: AddItemIntent(),
            phrases: [
                "Add a subscription in \(.applicationName)",
                "Add a \(\.$kind) in \(.applicationName)",
                "New item in \(.applicationName)"
            ],
            shortTitle: "Add Item",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: OpenItemIntent(),
            phrases: [
                "Open \(\.$item) in \(.applicationName)",
                "Show \(\.$item) in \(.applicationName)"
            ],
            shortTitle: "Open Item",
            systemImageName: "doc.text.magnifyingglass"
        )
    }
}
