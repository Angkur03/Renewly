//
// SupportEmail.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import UIKit

nonisolated enum AppLinks {
    static let supportAddress = "support.applab.world@gmail.com"
    static let privacyPolicy = URL(string: "https://www.applab.world/privacy.html")
}

/// Details that help support reproduce a problem. Nothing personal: no item data, names or identifiers.
nonisolated struct DeviceInfo: Equatable, Sendable {
    let appVersion: String
    let build: String
    let systemName: String
    let systemVersion: String
    let deviceModel: String
    let locale: String
    let timeZone: String
    let plan: String

    @MainActor
    static func current(isPro: Bool, bundle: Bundle = .main, device: UIDevice = .current) -> DeviceInfo {
        DeviceInfo(
            appVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown",
            build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown",
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            deviceModel: modelIdentifier(fallback: device.model),
            locale: Locale.current.identifier,
            timeZone: TimeZone.current.identifier,
            plan: isPro ? "Pro" : "Free"
        )
    }

    /// The hardware identifier, e.g. "iPhone16,2". `UIDevice.model` only says "iPhone".
    private static func modelIdentifier(fallback: String) -> String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return "\(simulated) (Simulator)"
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
        return identifier.isEmpty ? fallback : identifier
    }
}

nonisolated struct SupportEmail: Equatable, Sendable {
    let recipient: String
    let subject: String
    let body: String

    init(info: DeviceInfo, recipient: String = AppLinks.supportAddress) {
        self.recipient = recipient
        subject = "Renewly Support (v\(info.appVersion))"
        body = """


        Please describe your question or the problem above this line.

        ---
        Device details
        App: Renewly \(info.appVersion) (\(info.build))
        Plan: \(info.plan)
        \(info.systemName): \(info.systemVersion)
        Device: \(info.deviceModel)
        Language: \(info.locale)
        Time zone: \(info.timeZone)
        """
    }

    /// Fallback for devices without Mail set up; opens the default mail app.
    var mailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}
