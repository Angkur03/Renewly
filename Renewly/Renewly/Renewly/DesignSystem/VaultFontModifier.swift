//
// VaultFontModifier.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var isProUser: Bool = false
    @Entry var vaultFontFamily: VaultFontFamily = .system
}

struct VaultFontModifier: ViewModifier {
    let style: Font.TextStyle

    @Environment(\.isProUser) private var isProUser
    @Environment(\.vaultFontFamily) private var selectedFamily

    func body(content: Content) -> some View {
        content.font(VaultFontFamily.resolved(selected: selectedFamily, isPro: isProUser).font(for: style))
    }
}

extension View {
    func vaultFont(_ style: Font.TextStyle) -> some View {
        modifier(VaultFontModifier(style: style))
    }
}
