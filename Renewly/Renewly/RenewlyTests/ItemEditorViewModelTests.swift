//
// ItemEditorViewModelTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import SwiftData
import Testing
@testable import Renewly

@MainActor
@Suite("Item editor edge cases")
struct ItemEditorViewModelTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .distantPast
    }

    private func day(of date: Date) -> DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }

    private var now: Date { date(2026, 6, 15) }

    private func makeViewModel(item: TrackedItem? = nil) -> ItemEditorViewModel {
        ItemEditorViewModel(
            item: item,
            defaultCurrency: "USD",
            dependencies: PreviewData.dependencies(),
            now: now,
            calendar: calendar
        )
    }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(for: TrackedItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    @Test("A past start date suggests the next upcoming renewal")
    func suggestedRenewalFollowsStartDate() {
        let viewModel = makeViewModel()
        viewModel.startDate = date(2026, 1, 20)
        #expect(day(of: viewModel.expirationDate) == DateComponents(year: 2026, month: 6, day: 20))

        viewModel.billingCycle = .yearly
        #expect(day(of: viewModel.expirationDate) == DateComponents(year: 2027, month: 1, day: 20))
    }

    @Test("Switching to a warranty suggests one year of coverage")
    func warrantyDefaultsToOneYear() {
        let viewModel = makeViewModel()
        viewModel.category = .warranty
        viewModel.startDate = date(2026, 3, 1)
        #expect(day(of: viewModel.expirationDate) == DateComponents(year: 2027, month: 3, day: 1))
    }

    @Test("A manually chosen end date is never overwritten")
    func manualDateSticks() {
        let viewModel = makeViewModel()
        viewModel.setExpirationDate(date(2026, 12, 25))
        viewModel.startDate = date(2026, 6, 1)
        viewModel.billingCycle = .quarterly
        #expect(day(of: viewModel.expirationDate) == DateComponents(year: 2026, month: 12, day: 25))
    }

    @Test("Editing an existing item keeps its stored dates")
    func existingItemKeepsDates() {
        let item = TrackedItem(
            title: "Spotify", category: .subscription, cost: 11, currencyCode: "USD",
            startDate: date(2025, 1, 5), expirationDate: date(2026, 7, 5)
        )
        let viewModel = makeViewModel(item: item)
        viewModel.startDate = date(2025, 2, 1)
        #expect(day(of: viewModel.expirationDate) == DateComponents(year: 2026, month: 7, day: 5))
    }

    @Test("Prices above the cap are rejected", arguments: [
        (999_999_999.0, true), (1_000_000_000.0, true), (1_000_000_000.01, false), (-1.0, false)
    ])
    func priceCap(cost: Double, isValid: Bool) {
        let viewModel = makeViewModel()
        viewModel.title = "Item"
        viewModel.cost = cost
        #expect((viewModel.validationMessage == nil) == isValid)
    }

    @Test("A past subscription date is saved as the next renewal")
    func pastSubscriptionRollsForwardOnSave() async throws {
        let context = try makeContext()
        let viewModel = makeViewModel()
        viewModel.title = "Gym"
        viewModel.startDate = date(2026, 1, 10)
        viewModel.setExpirationDate(date(2026, 2, 10))
        viewModel.isNotificationEnabled = false

        #expect(viewModel.rolloverHint != nil)
        #expect(await viewModel.save(in: context, activeAlertItemIDs: []))

        let saved = try context.fetch(FetchDescriptor<TrackedItem>())
        #expect(saved.count == 1)
        #expect(day(of: saved[0].expirationDate) == DateComponents(year: 2026, month: 7, day: 10))
    }

    @Test("Expired warranties cannot keep reminders on")
    func expiredWarrantyDisablesReminders() async throws {
        let context = try makeContext()
        let viewModel = makeViewModel()
        viewModel.title = "Old Laptop"
        viewModel.category = .warranty
        viewModel.startDate = date(2023, 1, 1)
        viewModel.setExpirationDate(date(2024, 1, 1))
        viewModel.isNotificationEnabled = true

        #expect(!viewModel.canEnableReminders)
        #expect(viewModel.rolloverHint == nil)
        #expect(await viewModel.save(in: context, activeAlertItemIDs: []))

        let saved = try context.fetch(FetchDescriptor<TrackedItem>())
        #expect(saved.first?.isNotificationEnabled == false)
        #expect(day(of: saved[0].expirationDate) == DateComponents(year: 2024, month: 1, day: 1))
    }

    @Test("New expired warranties start with reminders off")
    func defaultReminderRespectsExpiry() {
        let viewModel = makeViewModel()
        viewModel.category = .warranty
        viewModel.startDate = date(2023, 1, 1)
        viewModel.setExpirationDate(date(2024, 1, 1))
        viewModel.applyDefaultReminder(activeAlertItemIDs: [])
        #expect(!viewModel.isNotificationEnabled)
    }
}
