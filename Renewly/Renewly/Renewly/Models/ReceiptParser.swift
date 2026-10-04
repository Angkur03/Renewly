//
// ReceiptParser.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// Details read from a receipt, warranty card or subscription email. Every field is optional:
/// OCR is best-effort, and the editor only fills fields the user has not already set.
nonisolated struct ReceiptScan: Equatable, Sendable {
    var merchant: String?
    var total: Double?
    var currencyCode: String?
    var purchaseDate: Date?
    /// A future date labelled as a renewal, billing or expiry date.
    var renewalDate: Date?
    var serialNumber: String?
    var warrantyMonths: Int?
    var billingCycle: BillingCycle?
    var suggestedCategory: ItemCategory?
    /// The text mentions a free trial, so the renewal date is likely the first charge.
    var isFreeTrial = false

    var isEmpty: Bool {
        merchant == nil && total == nil && currencyCode == nil && purchaseDate == nil && renewalDate == nil
            && serialNumber == nil && warrantyMonths == nil && billingCycle == nil && !isFreeTrial
    }
}

nonisolated enum ReceiptParser {
    static func parse(lines rawLines: [String], defaultCurrency: String, now: Date, calendar: Calendar = .current) -> ReceiptScan {
        let lines = rawLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { return ReceiptScan() }

        let text = lines.joined(separator: "\n")
        let dates = self.dates(in: lines, now: now, calendar: calendar)
        let serial = serialNumber(in: lines)
        let warranty = warrantyMonths(in: text)
        let cycle = billingCycle(in: text)

        return ReceiptScan(
            merchant: merchant(in: lines),
            total: total(in: lines),
            currencyCode: currency(in: text, defaultCurrency: defaultCurrency),
            purchaseDate: dates.purchase,
            renewalDate: dates.renewal,
            serialNumber: serial,
            warrantyMonths: warranty,
            billingCycle: cycle,
            suggestedCategory: category(in: text, hasSerial: serial != nil, hasWarranty: warranty != nil, cycle: cycle),
            isFreeTrial: mentionsFreeTrial(in: text)
        )
    }

    // MARK: Amounts

    private static let totalKeywords = [
        "grand total", "total due", "amount due", "balance due", "total amount", "net total",
        "amount paid", "total paid", "order total", "total", "amount", "paid", "price"
    ]
    /// Lines that carry an amount but never the total. "Total (incl. VAT)" is still a total, so tax words only
    /// disqualify a line when they lead it.
    private static let excludedAmountPhrases = [
        "subtotal", "sub total", "sub-total", "total tax", "tax total", "total vat", "saving", "change due",
        "change", "tendered", "rounding", "points", "total items", "total qty", "quantity"
    ]
    private static let excludedAmountPrefixes = ["tax", "vat", "gst", "discount", "cash", "tip", "qty", "item"]

    private static func isExcludedAmountLine(_ lower: String) -> Bool {
        excludedAmountPhrases.contains { lower.contains($0) } || excludedAmountPrefixes.contains { lower.hasPrefix($0) }
    }

    /// Prefers the amount on (or right after) the strongest "total" line; otherwise the largest price on the page.
    static func total(in lines: [String]) -> Double? {
        var best: (priority: Int, index: Int, amount: Double)?
        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()
            guard !isExcludedAmountLine(lower),
                  let priority = totalKeywords.firstIndex(where: { lower.contains($0) }) else { continue }
            let sameLine = amounts(in: line).last
            let nextLine = lines.indices.contains(index + 1) ? amounts(in: lines[index + 1]).first : nil
            guard let amount = sameLine ?? nextLine, amount > 0 else { continue }
            if best == nil || priority < best?.priority ?? .max || (priority == best?.priority && index > best?.index ?? .max) {
                best = (priority, index, amount)
            }
        }
        if let best { return best.amount }

        return lines
            .filter { !isExcludedAmountLine($0.lowercased()) }
            .flatMap { amounts(in: $0) }
            .filter { $0 > 0 }
            .max()
    }

    /// Money-looking numbers: either written with a currency marker ("Tk 1,500", "$9") or with two decimals ("24.99").
    static func amounts(in line: String) -> [Double] {
        let pattern = #"(?<![\d.,])((?:US\$|[$€£¥₹৳]|(?i:tk|bdt|usd|eur|gbp|inr|jpy|rs)\.?)\s?)?(\d{1,3}(?:[,.']\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)(?![\d]|[.,/\-:]\d)(\s?(?:[€£৳]|(?i:tk|bdt|usd|eur|gbp|inr|jpy)\b))?"#
        guard let regex = regex(pattern) else { return [] }
        let range = NSRange(line.startIndex..., in: line)
        return regex.matches(in: line, range: range).compactMap { match in
            guard let numberRange = Range(match.range(at: 2), in: line) else { return nil }
            let number = String(line[numberRange])
            let hasMarker = match.range(at: 1).location != NSNotFound || match.range(at: 3).location != NSNotFound
            let hasCents = number.range(of: #"[.,]\d{2}$"#, options: .regularExpression) != nil
            guard hasMarker || hasCents else { return nil }
            return parseNumber(number)
        }
    }

    /// Handles "1,299.00", "1.299,00", "12,99" and "1,500".
    static func parseNumber(_ raw: String) -> Double? {
        let cleaned = raw.filter { $0.isNumber || $0 == "." || $0 == "," || $0 == "'" }
        guard !cleaned.isEmpty else { return nil }
        if let fractionRange = cleaned.range(of: #"[.,]\d{1,2}$"#, options: .regularExpression) {
            let integer = cleaned[..<fractionRange.lowerBound].filter(\.isNumber)
            let fraction = cleaned[fractionRange].dropFirst()
            return Double("\(integer.isEmpty ? "0" : String(integer)).\(fraction)")
        }
        return Double(cleaned.filter(\.isNumber))
    }

    // MARK: Currency

    private static let dollarCurrencies: Set<String> = ["USD", "CAD", "AUD", "NZD", "SGD", "HKD", "MXN", "TWD"]
    private static let knownCodes = [
        "USD", "EUR", "GBP", "JPY", "INR", "BDT", "CAD", "AUD", "CHF", "CNY", "SGD", "AED", "SAR",
        "MYR", "PKR", "NZD", "HKD", "SEK", "NOK", "DKK", "KRW", "THB", "IDR", "PHP", "LKR", "NPR"
    ]

    static func currency(in text: String, defaultCurrency: String) -> String? {
        var counts: [String: Int] = [:]
        func add(_ code: String, _ occurrences: Int) {
            guard occurrences > 0 else { return }
            counts[code, default: 0] += occurrences
        }
        let upper = text.uppercased()
        for code in knownCodes {
            add(code, occurrences(of: "\\b\(code)\\b", in: upper))
        }
        add("EUR", occurrences(of: "€", in: text))
        add("GBP", occurrences(of: "£", in: text))
        add("JPY", occurrences(of: "¥", in: text))
        add("INR", occurrences(of: "₹", in: text) + occurrences(of: "\\bRs\\.?\\s?\\d", in: text))
        add("BDT", occurrences(of: "৳", in: text) + occurrences(of: "\\b(?i:tk)\\.?\\s?\\d", in: text))
        add("USD", occurrences(of: "US\\$", in: text))
        let bareDollars = occurrences(of: "(?<!US)\\$", in: text)
        add(dollarCurrencies.contains(defaultCurrency) ? defaultCurrency : "USD", bareDollars)

        // Most mentions wins; ties go to the user's main currency, then alphabetically for stable results.
        return counts.max { lhs, rhs in
            (lhs.value, lhs.key == defaultCurrency ? 1 : 0, rhs.key) < (rhs.value, rhs.key == defaultCurrency ? 1 : 0, lhs.key)
        }?.key
    }

    // MARK: Dates

    private static let purchaseDateKeywords = ["date", "purchase", "order", "invoice", "transaction", "sold", "bought"]
    private static let renewalDateKeywords = ["renew", "next", "billing", "expire", "expiry", "valid until", "due", "until"]

    static func dates(in lines: [String], now: Date, calendar: Calendar) -> (purchase: Date?, renewal: Date?) {
        let detector: NSDataDetector
        do {
            detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        } catch {
            return (nil, nil)
        }
        let today = calendar.startOfDay(for: now)
        let earliest = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? .distantPast

        var purchase: (date: Date, hasKeyword: Bool)?
        var renewal: Date?
        for line in lines {
            let lower = line.lowercased()
            let range = NSRange(line.startIndex..., in: line)
            for match in detector.matches(in: line, range: range) {
                guard let date = match.date,
                      let matchRange = Range(match.range, in: line),
                      looksLikeCalendarDate(String(line[matchRange])),
                      date >= earliest else { continue }
                let day = calendar.startOfDay(for: date)
                if day > today {
                    if renewal == nil, renewalDateKeywords.contains(where: { lower.contains($0) }) {
                        renewal = date
                    }
                    continue
                }
                let hasKeyword = purchaseDateKeywords.contains { lower.contains($0) }
                if purchase == nil || (hasKeyword && purchase?.hasKeyword == false) {
                    purchase = (date, hasKeyword)
                }
            }
        }
        return (purchase?.date, renewal)
    }

    /// NSDataDetector also matches bare times ("10:45") and words like "today"; only accept real calendar dates.
    private static func looksLikeCalendarDate(_ text: String) -> Bool {
        let numeric = #"\d{1,4}[/.\-]\d{1,2}[/.\-]\d{2,4}"#
        let named = #"(?i)\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\b"#
        return text.range(of: numeric, options: .regularExpression) != nil
            || text.range(of: named, options: .regularExpression) != nil
    }

    // MARK: Merchant

    private static let merchantSkipWords = [
        "receipt", "invoice", "tax", "tel", "phone", "www", "http", ".com", "order", "date", "welcome",
        "thank", "customer", "cashier", "store #", "gst", "vat", "street", "road", "avenue", "suite",
        "page", "copy", "bill to", "ship to", "@"
    ]

    /// The shop name is usually one of the first few lines, made mostly of letters.
    static func merchant(in lines: [String]) -> String? {
        for line in lines.prefix(6) {
            let lower = line.lowercased()
            let letters = line.filter(\.isLetter).count
            let digits = line.filter(\.isNumber).count
            guard letters >= 3,
                  Double(digits) / Double(max(line.count, 1)) < 0.25,
                  !merchantSkipWords.contains(where: { lower.contains($0) }),
                  amounts(in: line).isEmpty else { continue }
            let trimmed = line.trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
            let name = trimmed == trimmed.uppercased() ? trimmed.capitalized : trimmed
            return String(name.prefix(80))
        }
        return nil
    }

    // MARK: Warranty details

    static func serialNumber(in lines: [String]) -> String? {
        let pattern = #"(?i)\b(?:serial\s*(?:no\.?|number|#)?|s/n|sn|imei)\s*[:#.\-]?\s*([A-Z0-9][A-Z0-9\-]{4,})"#
        guard let regex = regex(pattern) else { return nil }
        for line in lines {
            let range = NSRange(line.startIndex..., in: line)
            guard let match = regex.firstMatch(in: line, range: range),
                  let valueRange = Range(match.range(at: 1), in: line) else { continue }
            let value = line[valueRange].uppercased()
            if value.contains(where: \.isNumber) {
                return String(value.prefix(40))
            }
        }
        return nil
    }

    static func warrantyMonths(in text: String) -> Int? {
        let number = #"(\d{1,2}|one|two|three|four|five)"#
        let unit = #"(years?|yrs?|months?|mos?)"#
        let patterns = [
            "(?i)\(number)[\\s-]*\(unit)[^\\n]{0,25}warranty",
            "(?i)warranty[^\\n\\d]{0,25}\(number)[\\s-]*\(unit)"
        ]
        let words = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5]
        for pattern in patterns {
            guard let regex = regex(pattern) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            guard let match = regex.firstMatch(in: text, range: range),
                  let numberRange = Range(match.range(at: 1), in: text),
                  let unitRange = Range(match.range(at: 2), in: text) else { continue }
            let rawNumber = text[numberRange].lowercased()
            guard let value = Int(rawNumber) ?? words[rawNumber], value > 0 else { continue }
            let months = text[unitRange].lowercased().hasPrefix("y") ? value * 12 : value
            return min(months, 120)
        }
        return nil
    }

    // MARK: Subscriptions

    static func billingCycle(in text: String) -> BillingCycle? {
        let lower = text.lowercased()
        let checks: [(BillingCycle, [String])] = [
            (.quarterly, ["quarterly", "every 3 months", "/quarter", "per quarter"]),
            (.yearly, ["/year", "/yr", "per year", "yearly", "annual", "a year"]),
            (.monthly, ["/month", "/mo", "per month", "monthly", "a month"])
        ]
        return checks.first { _, keywords in keywords.contains { lower.contains($0) } }?.0
    }

    private static func category(in text: String, hasSerial: Bool, hasWarranty: Bool, cycle: BillingCycle?) -> ItemCategory? {
        let lower = text.lowercased()
        let subscriptionWords = ["subscription", "renews", "renewal", "membership", "plan", "trial", "auto-renew"]
        let warrantyWords = ["warranty", "imei", "model", "serial", "guarantee"]

        let subscriptionScore = (cycle == nil ? 0 : 2) + subscriptionWords.filter { lower.contains($0) }.count
        let warrantyScore = (hasSerial ? 2 : 0) + (hasWarranty ? 2 : 0) + warrantyWords.filter { lower.contains($0) }.count
        guard subscriptionScore != warrantyScore else { return nil }
        return subscriptionScore > warrantyScore ? .subscription : .warranty
    }

    private static let trialPhrases = ["free trial", "trial ends", "trial period", "trial expires", "your trial"]

    static func mentionsFreeTrial(in text: String) -> Bool {
        let lower = text.lowercased()
        return trialPhrases.contains { lower.contains($0) }
    }

    // MARK: Helpers

    private static func regex(_ pattern: String) -> NSRegularExpression? {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            assertionFailure("Invalid receipt pattern: \(pattern)")
            return nil
        }
    }

    private static func occurrences(of pattern: String, in text: String) -> Int {
        guard let regex = regex(pattern) else { return 0 }
        return regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    }
}
