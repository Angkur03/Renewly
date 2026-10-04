//
// ReminderPreferencesTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@Suite("Reminder preferences")
struct ReminderPreferencesTests {
    @Test("Defaults include every offset")
    func defaults() {
        let preferences = ReminderPreferences()
        #expect(preferences.isEnabled)
        #expect(preferences.offsets == [30, 7, 3, 1])
        #expect(preferences.scheduleDescription == "30, 7, 3 and 1 day before")
    }

    @Test("The 3-day reminder cannot be removed")
    func threeDaysIsRequired() {
        #expect(ReminderPreferences(offsets: []).offsets == [3])
        #expect(ReminderPreferences.toggling(3, isOn: false, in: "30,7,3,1") == "30,7,3,1")
        #expect(ReminderPreferences(isEnabled: true, offsetsRaw: "").offsets == [3])
    }

    @Test("Schedule descriptions", arguments: [
        ("3", "3 days before"),
        ("7,3", "7 and 3 days before"),
        ("3,1", "3 and 1 day before"),
        ("30,3", "30 and 3 days before")
    ])
    func descriptions(raw: String, expected: String) {
        #expect(ReminderPreferences(isEnabled: true, offsetsRaw: raw).scheduleDescription == expected)
    }

    @Test("Toggling optional offsets round-trips through storage")
    func toggling() {
        var raw = ReminderPreferences.defaultOffsetsRaw
        raw = ReminderPreferences.toggling(30, isOn: false, in: raw)
        raw = ReminderPreferences.toggling(1, isOn: false, in: raw)
        #expect(raw == "7,3")
        raw = ReminderPreferences.toggling(1, isOn: true, in: raw)
        #expect(raw == "7,3,1")
    }

    @Test("Unknown or malformed stored values are ignored")
    func decodingIsDefensive() {
        #expect(ReminderPreferences.decode("30, 5, abc,1") == [30, 1])
    }
}
