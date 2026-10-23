//
// DemoTour.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

#if DEBUG
import Foundation

/// A scripted walk through the main screens for the promo video, started with `-demo_tour YES`.
/// `marketing/tools/ComposePromoVideo.swift` times its captions to these stops, so change both together.
enum DemoTour {
    enum Stop: Equatable, Sendable {
        case dashboard
        case item(String)
        case insights
        case settings
        case newSubscription
    }

    static let launchKey = "demo_tour"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: launchKey)
    }

    /// Each stop and how long it stays on screen, in seconds.
    static let stops: [(stop: Stop, seconds: Double)] = [
        (.dashboard, 3),
        (.item("YouTube Premium"), 3.5),
        (.dashboard, 1),
        (.item("LG C3 OLED 65\""), 3),
        (.dashboard, 1),
        (.insights, 3.5),
        (.dashboard, 1),
        (.settings, 3),
        (.dashboard, 1),
        (.newSubscription, 4),
    ]
}
#endif
