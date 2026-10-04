//
// ReceiptScanEditorTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@MainActor
@Suite("Receipt scanning in the editor")
struct ReceiptScanEditorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 12)) ?? .distantPast
    }

    private let photo = Data([0xFF, 0xD8, 0xFF])

    private func day(of date: Date) -> DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }

    private func makeViewModel(recognizer: any ReceiptTextRecognizing = MockTextRecognizer()) -> ItemEditorViewModel {
        ItemEditorViewModel(
            item: nil,
            defaultCurrency: "USD",
            dependencies: PreviewData.dependencies(textRecognizer: recognizer),
            now: now,
            calendar: calendar
        )
    }

    @Test func fillsABlankNewItemFromTheReceipt() async {
        let viewModel = makeViewModel()

        await viewModel.receiptPicked(photo)

        #expect(viewModel.receiptPreviewData == photo)
        #expect(viewModel.isScanning == false)
        #expect(viewModel.category == .warranty)
        #expect(viewModel.title == "Apple Store")
        #expect(viewModel.retailer == "Apple Store")
        #expect(viewModel.cost == 271.10)
        #expect(viewModel.serialNumber == "GX7KL2MQ9P")
        #expect(day(of: viewModel.startDate) == DateComponents(year: 2026, month: 3, day: 14))
        #expect(day(of: viewModel.expirationDate) == DateComponents(year: 2027, month: 3, day: 14))
        #expect(viewModel.scanMessage?.hasPrefix("Filled in") == true)
    }

    @Test func neverOverwritesWhatTheUserTyped() async {
        let viewModel = makeViewModel()
        viewModel.category = .warranty
        viewModel.title = "My AirPods"
        viewModel.cost = 199
        let customEnd = calendar.date(byAdding: .year, value: 2, to: now) ?? now
        viewModel.setExpirationDate(customEnd)

        await viewModel.receiptPicked(photo)

        #expect(viewModel.title == "My AirPods")
        #expect(viewModel.cost == 199)
        #expect(viewModel.expirationDate == customEnd)
        #expect(viewModel.retailer == "Apple Store")
        #expect(viewModel.serialNumber == "GX7KL2MQ9P")
    }

    @Test func fillsASubscriptionWithItsRenewalDate() async {
        let recognizer = MockTextRecognizer(lines: [
            "Spotify",
            "Premium Family $16.99/month",
            "Your plan renews on 20 Oct 2026"
        ])
        let viewModel = makeViewModel(recognizer: recognizer)

        await viewModel.receiptPicked(photo)

        #expect(viewModel.category == .subscription)
        #expect(viewModel.title == "Spotify")
        #expect(viewModel.cost == 16.99)
        #expect(viewModel.billingCycle == .monthly)
        #expect(day(of: viewModel.expirationDate) == DateComponents(year: 2026, month: 10, day: 20))
    }

    @Test func switchesCurrencyWhenThePriceComesFromTheReceipt() async {
        let viewModel = makeViewModel(recognizer: MockTextRecognizer(lines: ["Currys", "Total €89,00"]))

        await viewModel.receiptPicked(photo)

        #expect(viewModel.cost == 89)
        #expect(viewModel.currencyCode == "EUR")
    }

    @Test func reportsRecognitionFailureAndKeepsThePhoto() async {
        let viewModel = makeViewModel(recognizer: MockTextRecognizer(error: .recognitionFailed))

        await viewModel.receiptPicked(photo)

        #expect(viewModel.receiptPreviewData == photo)
        #expect(viewModel.title.isEmpty)
        #expect(viewModel.scanMessage == ReceiptScanError.recognitionFailed.userMessage)
    }

    @Test func cancellationIsSilent() async {
        let viewModel = makeViewModel(recognizer: MockTextRecognizer(error: .cancelled))

        await viewModel.receiptPicked(photo)

        #expect(viewModel.scanMessage == nil)
        #expect(viewModel.isScanning == false)
    }

    @Test func explainsWhenNothingWasReadable() async {
        let viewModel = makeViewModel(recognizer: MockTextRecognizer(lines: ["~~~", "..."]))

        await viewModel.receiptPicked(photo)

        #expect(viewModel.scanMessage?.hasPrefix("No details") == true)
    }

    @Test func removingThePhotoClearsTheScanMessage() async {
        let viewModel = makeViewModel()
        await viewModel.receiptPicked(photo)

        viewModel.removeReceipt()

        #expect(viewModel.scanMessage == nil)
        #expect(viewModel.receiptPreviewData == nil)
    }

    @Test func rescanningTheAttachedPhotoFillsClearedFields() async {
        let viewModel = makeViewModel()
        await viewModel.receiptPicked(photo)
        viewModel.cost = 0

        await viewModel.scanAttachedReceipt()

        #expect(viewModel.cost == 271.10)
    }
}
