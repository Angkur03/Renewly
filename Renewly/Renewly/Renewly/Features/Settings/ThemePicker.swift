//
// ThemePicker.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

struct ThemePicker: View {
    @Binding var selection: AppTheme

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppTheme.allCases) { theme in
                tile(for: theme)
            }
        }
        .rigidHaptic(trigger: selection)
    }

    private func tile(for theme: AppTheme) -> some View {
        let isSelected = theme == selection
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return Button {
            withAnimation(.snappy) { selection = theme }
        } label: {
            VStack(spacing: 8) {
                ThemeSwatch(theme: theme)
                    .frame(height: 96)
                    .clipShape(shape)
                    .overlay(
                        shape.strokeBorder(
                            isSelected ? Color.accentColor : Color(.separator).opacity(0.6),
                            lineWidth: isSelected ? 2.5 : 1
                        )
                    )
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.accentColor)
                                .font(.title3)
                                .padding(6)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .scaleEffect(isSelected ? 1 : 0.97)

                VStack(spacing: 2) {
                    Label(theme.title, systemImage: theme.systemImage)
                        .appFont(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                    Text(theme.subtitle)
                        .appFont(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(theme.title) theme, \(theme.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A miniature of the theme's dashboard: background, two cards and an accent chip.
private struct ThemeSwatch: View {
    let theme: AppTheme

    var body: some View {
        switch theme {
        case .system:
            HStack(spacing: 0) {
                miniature(.clean, scheme: .light)
                miniature(.clean, scheme: .dark)
            }
        case .light:
            miniature(.ocean, scheme: .light)
        case .dark:
            miniature(.midnight, scheme: .dark)
        }
    }

    private func miniature(_ palette: ThemePalette, scheme: ColorScheme) -> some View {
        ZStack(alignment: .topLeading) {
            ThemeBackground(palette: palette)
            VStack(alignment: .leading, spacing: 6) {
                Capsule()
                    .fill(Color.primary.opacity(0.8))
                    .frame(width: 28, height: 5)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 18, height: 7)
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(palette.cardFill)
                        .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(palette.cardStroke, lineWidth: 0.5))
                        .overlay(alignment: .leading) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 6, height: 6)
                                Capsule()
                                    .fill(Color.primary.opacity(0.35))
                                    .frame(height: 3)
                            }
                            .padding(.horizontal, 5)
                        }
                        .frame(height: 16)
                }
            }
            .padding(9)
        }
        .environment(\.colorScheme, scheme)
        .clipped()
    }
}

#Preview {
    @Previewable @State var theme: AppTheme = .light
    Form {
        Section("Appearance") {
            ThemePicker(selection: $theme)
        }
    }
}
