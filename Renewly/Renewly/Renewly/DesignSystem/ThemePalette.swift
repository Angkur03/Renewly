//
// ThemePalette.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

extension Color {
    nonisolated init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Visual language per theme: Light is a soft ocean blue, System is flat and native, Dark is midnight glass.
nonisolated enum ThemePalette: Sendable, Equatable {
    case ocean
    case clean
    case midnight

    static func resolve(_ theme: AppTheme) -> ThemePalette {
        switch theme {
        case .system: .clean
        case .light: .ocean
        case .dark: .midnight
        }
    }

    var cardFill: AnyShapeStyle {
        switch self {
        case .ocean: AnyShapeStyle(Color.white.opacity(0.82))
        case .clean: AnyShapeStyle(Color(.secondarySystemGroupedBackground))
        case .midnight: AnyShapeStyle(.ultraThinMaterial)
        }
    }

    var cardStroke: Color {
        switch self {
        case .ocean: Color(hex: 0xC9DCFF)
        case .clean: Color(.separator).opacity(0.35)
        case .midnight: Color.white.opacity(0.10)
        }
    }

    var cardShadow: Color {
        switch self {
        case .ocean: Color(hex: 0x1D4ED8, opacity: 0.10)
        case .clean: Color.black.opacity(0.04)
        case .midnight: Color.black.opacity(0.30)
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .ocean: 18
        case .clean: 6
        case .midnight: 16
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .ocean: 8
        case .clean: 2
        case .midnight: 8
        }
    }

    var chipFill: AnyShapeStyle {
        switch self {
        case .ocean: AnyShapeStyle(Color.white.opacity(0.85))
        case .clean: AnyShapeStyle(Color(.tertiarySystemFill))
        case .midnight: AnyShapeStyle(.ultraThinMaterial)
        }
    }

    var chipStroke: Color {
        switch self {
        case .ocean: Color(hex: 0xC9DCFF)
        case .clean: Color.clear
        case .midnight: Color.white.opacity(0.10)
        }
    }
}

struct ThemeBackground: View {
    let palette: ThemePalette

    var body: some View {
        switch palette {
        case .ocean:
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: 0xD3E4FF), Color(hex: 0xE8F1FF), Color(hex: 0xF6F9FF)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    glow(Color(hex: 0x60A5FA, opacity: 0.45), diameter: size.width * 1.1, x: size.width * 0.45, y: -size.height * 0.32)
                    glow(Color(hex: 0x818CF8, opacity: 0.25), diameter: size.width * 0.9, x: -size.width * 0.45, y: -size.height * 0.02)
                    glow(Color(hex: 0x38BDF8, opacity: 0.20), diameter: size.width, x: size.width * 0.4, y: size.height * 0.42)
                }
            }
        case .clean:
            Color(.systemGroupedBackground)
        case .midnight:
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: 0x0A0F24), Color(hex: 0x0E1530), Color(hex: 0x140F33)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    glow(Color(hex: 0x4F46E5, opacity: 0.38), diameter: size.width * 1.1, x: -size.width * 0.35, y: -size.height * 0.32)
                    glow(Color(hex: 0xA855F7, opacity: 0.22), diameter: size.width * 0.9, x: size.width * 0.45, y: size.height * 0.35)
                }
            }
        }
    }

    private func glow(_ color: Color, diameter: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .blur(radius: diameter * 0.28)
            .offset(x: x, y: y)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Full-screen background for the current theme.
struct AppBackground: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        ThemeBackground(palette: ThemePalette.resolve(theme))
            .ignoresSafeArea()
    }
}

private struct CardSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat

    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        let palette = ThemePalette.resolve(theme)
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(palette.cardFill, in: shape)
            .overlay(shape.strokeBorder(palette.cardStroke, lineWidth: 1))
            .shadow(color: palette.cardShadow, radius: palette.shadowRadius, y: palette.shadowY)
    }
}

private struct ChipSurfaceModifier: ViewModifier {
    let isSelected: Bool

    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        let palette = ThemePalette.resolve(theme)
        content
            .background {
                if isSelected {
                    Capsule().fill(Color.accentColor.gradient)
                } else {
                    Capsule().fill(palette.chipFill)
                }
            }
            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : palette.chipStroke, lineWidth: 1))
            .shadow(color: isSelected ? Color.accentColor.opacity(0.30) : .clear, radius: 8, y: 4)
    }
}

extension View {
    func cardSurface(cornerRadius: CGFloat) -> some View {
        modifier(CardSurfaceModifier(cornerRadius: cornerRadius))
    }

    func chipSurface(isSelected: Bool) -> some View {
        modifier(ChipSurfaceModifier(isSelected: isSelected))
    }
}
