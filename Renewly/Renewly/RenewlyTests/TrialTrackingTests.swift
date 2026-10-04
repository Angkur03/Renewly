//
// TrialTrackingTests.swift
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
@Suite("Free trials")
struct TrialTrackingTests {
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

    private func snapshot(
        category: ItemCategory = .subscription,
        expiresIn days: Int,
        trialEndsIn trialDays: Int?
    ) -> ItemSnapshot {
        ItemSnapshot(
            id: UUID(),
            title: "YouTube Premium",
            category: category,
            cost: 13.99,
            currencyCode: "USD",
            expirationDate: day(days),
            billingCycle: .monthly,
            isNotificationEnabled: true,
            trialEndDate: trialDays.map(day)
        )
    }

    private func makeManager() -> NotificationManager {
        let now = now
        return NotificationManager(
            center: FakeNotificationCenter(),
            calendar: calendar,
            preferences: FixedReminderPreferences(),
            now: { now }
        )
    }

    private func makeEditor(item: TrackedItem? = nil) -> ItemEditorViewModel {
        ItemEditorViewModel(item: item, defaultCurrency: "USD", dependencies: PreviewData.dependencies(), now: now, calendar: calendar)
    }

    private func makeContext() throws -> ModelContext {
        ModelContext(try RenewlyStore.makeContainer(inMemory: true))
    }

    // MARK: Trial state

    @Test("A subscription is in trial only while its next charge is the trial's end")
    func trialState() {
        #expect(snapshot(expiresIn: 5, trialEndsIn: 5).isInTrial(calendar: calendar))
        #expect(!snapshot(expiresIn: 35, trialEndsIn: 5).isInTrial(calendar: calendar))
        #expect(!snapshot(expiresIn: 5, trialEndsIn: nil).isInTrial(calendar: calendar))
        #expect(!snapshot(category: .warranty, expiresIn: 5, trialEndsIn: 5).isInTrial(calendar: calendar))
    }

    @Test("Trial wording", arguments: [
        (0, "Trial ends today"), (1, "Trial ends tomorrow"), (6, "Trial ends in 6 days"), (-2, "Trial ended 2 days ago")
    ])
    func trialText(days: Int, expected: String) {
        #expect(ExpiryText.relative(days: days, category: .subscription, isTrial: true) == expected)
        #expect(ExpiryText.relative(days: days, category: .subscription, isTrial: false)
            == ExpiryText.relative(days: days, category: .subscription))
    }

    // MARK: Reminders

    @Test("Trials always get the day-before reminder, even on the free plan")
    func trialAddsDayBeforeReminder() {
        let free = ReminderPreferences().limited(isPro: false)
        #expect(NotificationManager.offsets(for: free, isTrial: false) == [ReminderPreferences.freeOffset])
        #expect(NotificationManager.offsets(for: free, isTrial: true) == [ReminderPreferences.freeOffset, 1])

        let pro = ReminderPreferences().limited(isPro: true)
        let proTrial = NotificationManager.offsets(for: pro, isTrial: true)
        #expect(proTrial.filter { $0 == 1 }.count == 1)
        #expect(proTrial == proTrial.sorted(by: >))
    }

    @Test("Trial reminders tell the user to cancel before being charged")
    func trialReminderBody() throws {
        let manager = makeManager()
        let item = snapshot(expiresIn: 10, trialEndsIn: 10)

        let alerts = manager.alerts(for: item, preferences: ReminderPreferences().limited(isPro: false))

        #expect(alerts.map(\.identifier) == ["\(item.id.uuidString)-7d", "\(item.id.uuidString)-1d"])
        let dayBefore = try #require(alerts.last)
        #expect(dayBefore.body == "Free trial ends tomorrow. Cancel before then to avoid being charged.")
    }

    @Test("Regular renewals keep their usual wording")
    func regularReminderBody() {
        let alerts = makeManager().alerts(for: snapshot(expiresIn: 10, trialEndsIn: nil))
        #expect(alerts.allSatisfy { !$0.body.contains("trial") })
    }

    // MARK: Editor

    @Test("Turning on a free trial suggests a one-week trial and saves the trial end")
    func editorSavesTrial() async throws {
        let context = try makeContext()
        let viewModel = makeEditor()
        viewModel.title = "YouTube Premium"
        viewModel.startDate = now
        viewModel.isFreeTrial = true
        viewModel.isNotificationEnabled = false

        #expect(calendar.isDate(viewModel.expirationDate, inSameDayAs: day(ItemEditorViewModel.defaultTrialDays)))
        #expect(viewModel.expirationLabel == "Trial ends")
        #expect(viewModel.trialHint != nil)
        #expect(await viewModel.save(in: context, activeAlertItemIDs: []))

        let saved = try #require(try context.fetch(FetchDescriptor<TrackedItem>()).first)
        #expect(saved.isInTrial(calendar: calendar))
        #expect(makeEditor(item: saved).isFreeTrial)
    }

    @Test("A trial whose end already passed is saved as a regular subscription")
    func pastTrialSavesAsRegular() async throws {
        let context = try makeContext()
        let viewModel = makeEditor()
        viewModel.title = "Hulu"
        viewModel.startDate = day(-20)
        viewModel.isFreeTrial = true
        viewModel.setExpirationDate(day(-13))
        viewModel.isNotificationEnabled = false

        #expect(viewModel.rolloverHint?.contains("trial has already ended") == true)
        #expect(await viewModel.save(in: context, activeAlertItemIDs: []))

        let saved = try #require(try context.fetch(FetchDescriptor<TrackedItem>()).first)
        #expect(saved.trialEndDate == nil)
        #expect(!saved.isInTrial(calendar: calendar))
    }

    @Test("Warranties never store a trial")
    func warrantiesIgnoreTrial() async throws {
        let context = try makeContext()
        let viewModel = makeEditor()
        viewModel.title = "AirPods"
        viewModel.isFreeTrial = true
        viewModel.category = .warranty
        viewModel.isNotificationEnabled = false

        #expect(await viewModel.save(in: context, activeAlertItemIDs: []))
        #expect(try context.fetch(FetchDescriptor<TrackedItem>()).first?.trialEndDate == nil)
    }

    // MARK: Scanning

    @Test("Receipts mentioning a free trial are detected", arguments: [
        ("Your free trial ends on July 1", true), ("Trial period: 7 days", true), ("Monthly plan renews July 1", false)
    ])
    func receiptTrialDetection(line: String, expected: Bool) {
        let scan = ReceiptParser.parse(lines: ["YouTube", line], defaultCurrency: "USD", now: now, calendar: calendar)
        #expect(scan.isFreeTrial == expected)
    }

    @Test("A scanned trial turns on the editor's trial switch")
    func scanAppliesTrial() {
        let viewModel = makeEditor()
        let filled = viewModel.applyScan(ReceiptScan(merchant: "YouTube", isFreeTrial: true))
        #expect(viewModel.isFreeTrial)
        #expect(filled.contains("free trial"))
    }

    // MARK: Backup

    @Test("Backups keep trials, and files without the field restore as regular subscriptions")
    func backupRoundTrip() async throws {
        let source = try makeContext()
        let trialEnd = day(7)
        let trial = TrackedItem(title: "YouTube Premium", category: .subscription, cost: 13.99, currencyCode: "USD",
                                startDate: now, expirationDate: trialEnd, trialEndDate: trialEnd)
        let regular = TrackedItem(title: "Netflix", category: .subscription, cost: 15.99, currencyCode: "USD",
                                  startDate: now, expirationDate: day(20))
        source.insert(trial)
        source.insert(regular)
        try source.save()

        let archive = await BackupService(receipts: InMemoryReceiptStore()).makeArchive(from: [trial, regular])
        let data = try BackupCoder.encode(archive)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.components(separatedBy: "\"trialEndDate\"").count == 2)

        let target = try makeContext()
        let summary = try await BackupService(receipts: InMemoryReceiptStore()).restore(try BackupCoder.decode(data), into: target)
        #expect(summary.added == 2)

        let restored = try target.fetch(FetchDescriptor<TrackedItem>(sortBy: [SortDescriptor(\.title)]))
        #expect(restored.map(\.title) == ["Netflix", "YouTube Premium"])
        #expect(restored[0].trialEndDate == nil)
        #expect(restored[1].isInTrial(calendar: calendar))
    }

    // MARK: Dashboard

    @Test("The next-renewal row knows when it is a trial")
    func dashboardNextUpTrial() {
        let summary = DashboardSummary.make(
            from: [snapshot(expiresIn: 3, trialEndsIn: 3), snapshot(expiresIn: 9, trialEndsIn: nil)],
            currencyCode: "USD",
            now: now,
            calendar: calendar
        )
        #expect(summary.nextRenewal?.isTrial == true)
        #expect(summary.nextRenewal?.daysLeft == 3)
    }
}
