//
// ReminderPreferences.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// User-controlled reminder settings. The 3-day reminder is always part of the schedule.
nonisolated struct ReminderPreferences: Equatable, Sendable {
    static let availableOffsets = [30, 7, 3, 1]
    static let requiredOffset = 3
    static let defaultOffsetsRaw = encode(Set(availableOffsets))

    let isEnabled: Bool
    /// Days before expiration, sorted from furthest to closest.
    let offsets: [Int]

    init(isEnabled: Bool = true, offsets: Set<Int> = Set(availableOffsets)) {
        self.isEnabled = isEnabled
        self.offsets = Self.availableOffsets.filter { offsets.contains($0) || $0 == Self.requiredOffset }
    }

    init(isEnabled: Bool, offsetsRaw: String) {
        self.init(isEnabled: isEnabled, offsets: Self.decode(offsetsRaw))
    }

    /// e.g. "30, 7, 3 and 1 day before"
    var scheduleDescription: String {
        let numbers = offsets.map(String.init)
        let unit = offsets.last == 1 ? "day" : "days"
        let list: String
        switch numbers.count {
        case 0: return "Off"
        case 1: list = numbers[0]
        default: list = numbers.dropLast().joined(separator: ", ") + " and " + (numbers.last ?? "")
        }
        return "\(list) \(unit) before"
    }

    /// The schedule a plan actually gets: free users only receive the 3-day reminder.
    func limited(isPro: Bool) -> ReminderPreferences {
        isPro ? self : ReminderPreferences(isEnabled: isEnabled, offsets: [Self.requiredOffset])
    }

    static func isRequired(_ offset: Int) -> Bool {
        offset == requiredOffset
    }

    static func title(for offset: Int) -> String {
        offset == 1 ? "1 day before" : "\(offset) days before"
    }

    static func encode(_ offsets: Set<Int>) -> String {
        availableOffsets.filter { offsets.contains($0) }.map(String.init).joined(separator: ",")
    }

    static func decode(_ raw: String) -> Set<Int> {
        let values = raw.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        return Set(values.filter { availableOffsets.contains($0) })
    }

    static func toggling(_ offset: Int, isOn: Bool, in raw: String) -> String {
        guard !isRequired(offset) else { return raw }
        var offsets = decode(raw)
        if isOn {
            offsets.insert(offset)
        } else {
            offsets.remove(offset)
        }
        return encode(offsets)
    }
}

nonisolated protocol ReminderPreferencesProviding: Sendable {
    func current() -> ReminderPreferences
}

nonisolated struct UserDefaultsReminderPreferences: ReminderPreferencesProviding {
    func current() -> ReminderPreferences {
        let defaults = UserDefaults.standard
        let isEnabled = defaults.object(forKey: AppStorageKey.remindersEnabled) as? Bool ?? true
        let raw = defaults.string(forKey: AppStorageKey.reminderOffsets) ?? ReminderPreferences.defaultOffsetsRaw
        return ReminderPreferences(isEnabled: isEnabled, offsetsRaw: raw)
    }
}

nonisolated struct FixedReminderPreferences: ReminderPreferencesProviding {
    let value: ReminderPreferences

    init(_ value: ReminderPreferences = ReminderPreferences()) {
        self.value = value
    }

    func current() -> ReminderPreferences { value }
}
