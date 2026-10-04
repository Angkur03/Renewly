//
// AppTypography.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

nonisolated enum AppTypography {
    /// System fonts with rounded, heavier titles; all styles scale with Dynamic Type.
    static func font(for style: Font.TextStyle) -> Font {
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

extension View {
    func appFont(_ style: Font.TextStyle) -> some View {
        font(AppTypography.font(for: style))
    }
}
