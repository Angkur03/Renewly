//
// ReviewPrompt.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// Decides when to ask for an App Store rating: after someone has added a few items, at most once per app version.
/// iOS still decides whether the prompt actually appears, and shows it at most three times a year.
struct ReviewPrompt {
    static let itemsBeforeAsking = 3

    private let defaults: UserDefaults
    private let currentVersion: String

    init(defaults: UserDefaults = .standard, currentVersion: String = Self.bundleVersion) {
        self.defaults = defaults
        self.currentVersion = currentVersion
    }

    /// Counts a newly added item and returns `true` when this is a good moment to ask.
    func recordAddedItem() -> Bool {
        let count = defaults.integer(forKey: AppStorageKey.reviewAddedItemCount) + 1
        defaults.set(count, forKey: AppStorageKey.reviewAddedItemCount)
        guard count >= Self.itemsBeforeAsking,
              defaults.string(forKey: AppStorageKey.reviewLastPromptVersion) != currentVersion else {
            return false
        }
        defaults.set(currentVersion, forKey: AppStorageKey.reviewLastPromptVersion)
        return true
    }

    static var bundleVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }
}
