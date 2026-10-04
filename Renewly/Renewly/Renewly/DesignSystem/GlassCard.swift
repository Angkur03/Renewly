//
// GlassCard.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

struct GlassCard<Content: View>: View {
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let content: Content

    init(cornerRadius: CGFloat = 24, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(cornerRadius: cornerRadius)
    }
}

#Preview("Themes") {
    HStack(spacing: 0) {
        ForEach(AppTheme.allCases) { theme in
            ZStack {
                AppBackground()
                GlassCard {
                    Text(theme.title)
                        .appFont(.headline)
                }
                .padding()
            }
            .environment(\.appTheme, theme)
            .environment(\.colorScheme, theme == .dark ? .dark : .light)
        }
    }
}
