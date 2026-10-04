//
// TrackedItem.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class TrackedItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryRaw: String
    var cost: Double
    var currencyCode: String
    var startDate: Date
    var expirationDate: Date
    var isNotificationEnabled: Bool
    var serialNumber: String?
    var retailer: String?
    var billingCycleRaw: String
    var cancellationURL: String?
    /// Path relative to Application Support; the container path can change between installs.
    var receiptImagePath: String?
    var createdAt: Date
    /// When a subscription's free trial converts to paid. Set to the first charge date when the item is saved as
    /// a trial; once the subscription rolls past it, the trial is over.
    var trialEndDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        category: ItemCategory,
        cost: Double,
        currencyCode: String,
        startDate: Date,
        expirationDate: Date,
        isNotificationEnabled: Bool = false,
        serialNumber: String? = nil,
        retailer: String? = nil,
        billingCycle: BillingCycle = .monthly,
        cancellationURL: String? = nil,
        receiptImagePath: String? = nil,
        createdAt: Date = .now,
        trialEndDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.cost = cost
        self.currencyCode = currencyCode
        self.startDate = startDate
        self.expirationDate = expirationDate
        self.isNotificationEnabled = isNotificationEnabled
        self.serialNumber = serialNumber
        self.retailer = retailer
        self.billingCycleRaw = billingCycle.rawValue
        self.cancellationURL = cancellationURL
        self.receiptImagePath = receiptImagePath
        self.createdAt = createdAt
        self.trialEndDate = trialEndDate
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .subscription }
        set { categoryRaw = newValue.rawValue }
    }

    var billingCycle: BillingCycle {
        get { BillingCycle(rawValue: billingCycleRaw) ?? .monthly }
        set { billingCycleRaw = newValue.rawValue }
    }

    var snapshot: ItemSnapshot {
        ItemSnapshot(
            id: id,
            title: title,
            category: category,
            cost: cost,
            currencyCode: currencyCode,
            expirationDate: expirationDate,
            billingCycle: billingCycle,
            isNotificationEnabled: isNotificationEnabled,
            trialEndDate: category == .subscription ? trialEndDate : nil
        )
    }

    func isInTrial(calendar: Calendar = .current) -> Bool {
        snapshot.isInTrial(calendar: calendar)
    }

    var validCancellationURL: URL? {
        guard let cancellationURL, let url = URL(string: cancellationURL),
              let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            return nil
        }
        return url
    }
}
