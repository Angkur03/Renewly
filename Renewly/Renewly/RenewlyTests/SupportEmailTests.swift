//
// SupportEmailTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@Suite("Support email")
struct SupportEmailTests {
    private let info = DeviceInfo(
        appVersion: "1.2",
        build: "34",
        systemName: "iOS",
        systemVersion: "18.1",
        deviceModel: "iPhone16,2",
        locale: "en_BD",
        timeZone: "Asia/Dhaka",
        plan: "Pro"
    )

    @Test func addressesSupportWithVersionInSubject() {
        let email = SupportEmail(info: info)
        #expect(email.recipient == "support.applab.world@gmail.com")
        #expect(email.subject == "Renewly Support (v1.2)")
    }

    @Test func bodyLeavesRoomToWriteThenListsDeviceDetails() {
        let body = SupportEmail(info: info).body
        #expect(body.hasPrefix("\n\n"))
        for line in [
            "App: Renewly 1.2 (34)",
            "Plan: Pro",
            "iOS: 18.1",
            "Device: iPhone16,2",
            "Language: en_BD",
            "Time zone: Asia/Dhaka"
        ] {
            #expect(body.contains(line), "Missing \(line)")
        }
    }

    @Test func mailtoLinkEncodesSubjectAndBody() throws {
        let email = SupportEmail(info: info)
        let url = try #require(email.mailtoURL)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(url.scheme == "mailto")
        #expect(components.path == "support.applab.world@gmail.com")
        #expect(components.queryItems?.first { $0.name == "subject" }?.value == email.subject)
        #expect(components.queryItems?.first { $0.name == "body" }?.value == email.body)
    }

    @Test func privacyPolicyLinkIsValid() throws {
        let url = try #require(AppLinks.privacyPolicy)
        #expect(url.absoluteString == "https://www.applab.world/privacy.html")
    }

    @MainActor
    @Test func currentDeviceInfoIsFilledIn() {
        let current = DeviceInfo.current(isPro: false)
        #expect(current.plan == "Free")
        #expect(!current.systemVersion.isEmpty)
        #expect(!current.deviceModel.isEmpty)
        #expect(current.appVersion != "Unknown")
    }
}
