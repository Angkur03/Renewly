//
// RenewalRolloverService.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import OSLog
import SwiftData

/// Subscriptions renew automatically, so once a renewal date passes the item moves to its next
/// renewal instead of showing as expired. Warranties are left alone; they really do expire.
@MainActor
struct RenewalRolloverService {
    private let calendar: Calendar
    private let logger = Logger(subsystem: "com.beleiveinAllahRenewly.Renewly", category: "Rollover")

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Returns how many subscriptions were moved forward.
    @discardableResult
    func rollForward(in context: ModelContext, now: Date = .now) -> Int {
        let subscriptionRaw = ItemCategory.subscription.rawValue
        let startOfToday = calendar.startOfDay(for: now)
        let descriptor = FetchDescriptor<TrackedItem>(
            predicate: #Predicate { $0.categoryRaw == subscriptionRaw && $0.expirationDate < startOfToday }
        )

        let lapsed: [TrackedItem]
        do {
            lapsed = try context.fetch(descriptor)
        } catch {
            logger.error("Rollover fetch failed: \(error.localizedDescription, privacy: .public)")
            return 0
        }
        guard !lapsed.isEmpty else { return 0 }

        for item in lapsed {
            item.expirationDate = item.billingCycle.nextRenewal(from: item.expirationDate, onOrAfter: now, calendar: calendar)
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            logger.error("Rollover could not be saved.")
            return 0
        }
        return lapsed.count
    }
}
