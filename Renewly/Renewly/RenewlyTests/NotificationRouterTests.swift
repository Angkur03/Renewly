//
// NotificationRouterTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@MainActor
@Suite("Notification tap routing")
struct NotificationRouterTests {
    @Test func tappedItemIsHandedOverExactlyOnce() {
        let router = NotificationRouter()
        let itemID = UUID()

        router.open(itemID: itemID)

        #expect(router.pendingItemID == itemID)
        #expect(router.consume() == itemID)
        #expect(router.pendingItemID == nil)
        #expect(router.consume() == nil)
    }

    @Test func latestTapWins() {
        let router = NotificationRouter()
        let second = UUID()

        router.open(itemID: UUID())
        router.open(itemID: second)

        #expect(router.consume() == second)
    }
}
