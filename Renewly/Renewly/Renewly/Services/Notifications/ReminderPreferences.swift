//
// ReminderPreferences.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// User-controlled reminder settings. On Pro the 3-day reminder is always part of the schedule;
/// the free plan gets only the 7-day reminder.
nonisolated struct ReminderPreferences: Equatable, Sendable {
    static let availableOffsets = [30, 7, 3, 1]
    static let requiredOffset = 3
    static let freeOffset = 7
    static let defaultOffsetsRaw = encode(Set(availableOffsets))

    let isEnabled: Bool
    /// Days before expiration, sorted from furthest to closest.
    let offsets: [Int]

    init(isEnabled: Bool = true, offsets: Set<Int> = Set(availableOffsets)) {
        self.init(isEnabled: isEnabled, exactOffsets: offsets.union([Self.requiredOffset]))
    }

    private init(isEnabled: Bool, exactOffsets: Set<Int>) {
        self.isEnabled = isEnabled
        self.offsets = Self.availableOffsets.filter { exactOffsets.contains($0) }
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

    /// The schedule a plan actually gets: free users only receive the 7-day reminder.
    func limited(isPro: Bool) -> ReminderPreferences {
        isPro ? self : ReminderPreferences(isEnabled: isEnabled, exactOffsets: [Self.freeOffset])
    }

    /// Days before expiry within which saving an item delivers one alert right away, because a reminder
    /// whose time already passed would never fire: the 3-day reminder on Pro, the 7-day one on the free plan.
    var catchUpWindow: Int {
        offsets.contains(Self.requiredOffset) ? Self.requiredOffset : (offsets.last ?? Self.requiredOffset)
    }

    /// The Pro reminder that cannot be switched off.
    static func isRequired(_ offset: Int) -> Bool {
        offset == requiredOffset
    }

    /// Reminders shown as permanently on for the plan: 3 days on Pro, 7 days on the free plan.
    static func isAlwaysOn(_ offset: Int, isPro: Bool) -> Bool {
        offset == (isPro ? requiredOffset : freeOffset)
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
