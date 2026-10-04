//
// VaultFont.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI
import UIKit

nonisolated enum VaultFontFamily: String, CaseIterable, Identifiable, Sendable {
    case system
    case clashDisplay
    case satoshi
    case jetBrainsMono

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "SF Pro"
        case .clashDisplay: "Clash Display"
        case .satoshi: "Satoshi"
        case .jetBrainsMono: "JetBrains Mono"
        }
    }

    var postScriptName: String? {
        switch self {
        case .system: nil
        case .clashDisplay: "ClashDisplay-Medium"
        case .satoshi: "Satoshi-Bold"
        case .jetBrainsMono: "JetBrainsMono-Regular"
        }
    }

    var requiresPro: Bool { self != .system }

    /// Custom families fall back to the system font until their files are bundled.
    var isInstalled: Bool {
        guard let postScriptName else { return true }
        return UIFont(name: postScriptName, size: 12) != nil
    }

    func font(for style: Font.TextStyle) -> Font {
        guard let postScriptName, isInstalled else {
            return Self.systemFont(for: style)
        }
        return .custom(postScriptName, size: style.defaultPointSize, relativeTo: style)
    }

    static func resolved(selected: VaultFontFamily, isPro: Bool) -> VaultFontFamily {
        isPro ? selected : .system
    }

    static func systemFont(for style: Font.TextStyle) -> Font {
        switch style {
        case .largeTitle, .title, .title2, .title3:
            .system(style, design: .rounded, weight: .bold)
        case .headline:
            .system(style, design: .rounded, weight: .semibold)
        default:
            .system(style)
        }
    }
}

extension Font.TextStyle {
    /// Default sizes at the Large content size category, used as the base for `relativeTo:` scaling.
    nonisolated var defaultPointSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }
}
