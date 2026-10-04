//
// BillingCycle.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum BillingCycle: String, CaseIterable, Identifiable, Sendable {
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .yearly: "Yearly"
        }
    }

    var shortSuffix: String {
        switch self {
        case .monthly: "/mo"
        case .quarterly: "/qtr"
        case .yearly: "/yr"
        }
    }

    var monthsPerCycle: Int {
        switch self {
        case .monthly: 1
        case .quarterly: 3
        case .yearly: 12
        }
    }

    func monthlyEquivalent(of cost: Double) -> Double {
        cost / Double(monthsPerCycle)
    }
}
