//
// ReceiptParserTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@Suite("Receipt text parsing")
struct ReceiptParserTests {
    /// NSDataDetector resolves dates in the device time zone, so compare days in the same zone.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 12)) ?? .distantPast
    }

    private func day(of date: Date?) -> DateComponents? {
        date.map { calendar.dateComponents([.year, .month, .day], from: $0) }
    }

    private func parse(_ lines: [String], currency: String = "USD") -> ReceiptScan {
        ReceiptParser.parse(lines: lines, defaultCurrency: currency, now: now, calendar: calendar)
    }

    @Test func readsAStoreReceiptWithWarranty() {
        let scan = parse(MockTextRecognizer.sampleReceipt)

        #expect(scan.merchant == "Apple Store")
        #expect(scan.total == 271.10)
        #expect(scan.currencyCode == "USD")
        #expect(day(of: scan.purchaseDate) == DateComponents(year: 2026, month: 3, day: 14))
        #expect(scan.serialNumber == "GX7KL2MQ9P")
        #expect(scan.warrantyMonths == 12)
        #expect(scan.suggestedCategory == .warranty)
        #expect(scan.renewalDate == nil)
    }

    @Test func readsASubscriptionEmail() {
        let scan = parse([
            "Netflix",
            "Your membership renews on 15 Nov 2026",
            "Premium plan $22.99/month",
            "Billed on Oct 1, 2026"
        ])

        #expect(scan.merchant == "Netflix")
        #expect(scan.total == 22.99)
        #expect(scan.billingCycle == .monthly)
        #expect(scan.suggestedCategory == .subscription)
        #expect(day(of: scan.renewalDate) == DateComponents(year: 2026, month: 11, day: 15))
        #expect(day(of: scan.purchaseDate) == DateComponents(year: 2026, month: 10, day: 1))
    }

    @Test func prefersGrandTotalOverSubtotalTaxAndChange() {
        let scan = parse(["Subtotal 10.00", "Tax 0.80", "Grand Total 10.80", "Cash 20.00", "Change 9.20"])
        #expect(scan.total == 10.80)
    }

    @Test func keepsTotalsThatMentionTax() {
        let scan = parse(["Currys", "Subtotal €1.000,00", "VAT €190,00", "Total (incl. VAT) €1.190,00"], currency: "GBP")
        #expect(scan.total == 1_190)
        #expect(scan.currencyCode == "EUR")
    }

    @Test func readsTotalPrintedOnTheNextLine() {
        #expect(parse(["TOTAL", "$45.00"]).total == 45)
    }

    @Test func readsTakaWithoutDecimals() {
        let scan = parse(["Star Tech", "Amount Paid: Tk 1,500"])
        #expect(scan.total == 1_500)
        #expect(scan.currencyCode == "BDT")
    }

    @Test func fallsBackToLargestPriceWithoutTotalLine() {
        #expect(parse(["Cable 9.99", "Charger 24.50"]).total == 24.50)
    }

    @Test func ignoresDatesTimesAndPhoneNumbersAsAmounts() {
        #expect(ReceiptParser.amounts(in: "Tel 555-1234 at 10:45").isEmpty)
        #expect(ReceiptParser.amounts(in: "Date 03.14.2026").isEmpty)
        #expect(ReceiptParser.amounts(in: "Qty 2").isEmpty)
    }

    @Test(arguments: [
        ("1,299.00", 1_299.0),
        ("1.299,00", 1_299.0),
        ("12,99", 12.99),
        ("1,500", 1_500.0),
        ("9.5", 9.5)
    ])
    func parsesNumberFormats(raw: String, expected: Double) {
        #expect(ReceiptParser.parseNumber(raw) == expected)
    }

    @Test func bareDollarFollowsTheMainDollarCurrency() {
        #expect(ReceiptParser.currency(in: "Total $12.00", defaultCurrency: "CAD") == "CAD")
        #expect(ReceiptParser.currency(in: "Total $12.00", defaultCurrency: "EUR") == "USD")
        #expect(ReceiptParser.currency(in: "Total 12.00", defaultCurrency: "EUR") == nil)
    }

    @Test(arguments: [
        ("Warranty: 24 months", 24),
        ("2-year warranty included", 24),
        ("Limited warranty for one year", 12),
        ("No guarantee", nil)
    ] as [(String, Int?)])
    func readsWarrantyLength(text: String, months: Int?) {
        #expect(ReceiptParser.warrantyMonths(in: text) == months)
    }

    @Test func readsBillingCycles() {
        #expect(ReceiptParser.billingCycle(in: "$99.99 per year") == .yearly)
        #expect(ReceiptParser.billingCycle(in: "Billed quarterly") == .quarterly)
        #expect(ReceiptParser.billingCycle(in: "Coffee 3.50") == nil)
    }

    @Test func readsSerialNumberVariants() {
        #expect(ReceiptParser.serialNumber(in: ["S/N: ab12-cd34"]) == "AB12-CD34")
        #expect(ReceiptParser.serialNumber(in: ["IMEI 356938035643809"]) == "356938035643809")
        #expect(ReceiptParser.serialNumber(in: ["Serial number: pending"]) == nil)
    }

    @Test func skipsHeaderNoiseWhenFindingMerchant() {
        let merchant = ReceiptParser.merchant(in: ["TAX INVOICE", "www.example.com", "BEST BUY", "Store #123"])
        #expect(merchant == "Best Buy")
    }

    @Test func emptyTextGivesEmptyScan() {
        #expect(parse([]).isEmpty)
        #expect(parse(["   ", ""]).isEmpty)
    }
}
