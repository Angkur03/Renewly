//
// AppTheme.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI
import UIKit

nonisolated enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var subtitle: String {
        switch self {
        case .system: "Clean & adaptive"
        case .light: "Soft ocean blue"
        case .dark: "Midnight glass"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.stars.fill"
        }
    }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}

extension EnvironmentValues {
    @Entry var appTheme: AppTheme = .system
}

/// Applies the theme at the window level. `preferredColorScheme(nil)` does not reliably return to the
/// device appearance after a forced Light or Dark, so the window override is set directly instead.
@MainActor
enum InterfaceStyleController {
    static func apply(_ theme: AppTheme, animated: Bool) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows where window.overrideUserInterfaceStyle != theme.userInterfaceStyle {
            guard animated else {
                window.overrideUserInterfaceStyle = theme.userInterfaceStyle
                continue
            }
            UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
                window.overrideUserInterfaceStyle = theme.userInterfaceStyle
            }
        }
    }
}
