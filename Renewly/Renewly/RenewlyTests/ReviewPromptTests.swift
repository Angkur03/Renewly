//
// ReviewPromptTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@MainActor
@Suite("Review prompt")
struct ReviewPromptTests {
    private func makeDefaults() throws -> UserDefaults {
        let suite = "ReviewPromptTests-\(UUID().uuidString)"
        return try #require(UserDefaults(suiteName: suite))
    }

    @Test("Asks on the third added item, not before")
    func asksAfterThreeItems() throws {
        let prompt = ReviewPrompt(defaults: try makeDefaults(), currentVersion: "1.0")
        #expect(!prompt.recordAddedItem())
        #expect(!prompt.recordAddedItem())
        #expect(prompt.recordAddedItem())
    }

    @Test("Asks at most once per app version")
    func oncePerVersion() throws {
        let defaults = try makeDefaults()
        let firstVersion = ReviewPrompt(defaults: defaults, currentVersion: "1.0")
        for _ in 0..<3 { _ = firstVersion.recordAddedItem() }
        #expect(!firstVersion.recordAddedItem())
        #expect(!firstVersion.recordAddedItem())

        let update = ReviewPrompt(defaults: defaults, currentVersion: "1.1")
        #expect(update.recordAddedItem())
        #expect(!update.recordAddedItem())
    }
}
