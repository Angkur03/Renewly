//
// CurrencyBadge.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

struct CurrencyBadge: View {
    let option: CurrencyOption
    var size: CGFloat = 40

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
        Text(option.symbol)
            .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .padding(size * 0.12)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint.gradient, in: shape)
            .overlay(shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
            .overlay(alignment: .bottomTrailing) {
                if let flag = option.flag {
                    Text(flag)
                        .font(.system(size: size * 0.36))
                        .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                        .offset(x: size * 0.14, y: size * 0.14)
                }
            }
            .accessibilityHidden(true)
    }

    /// Stable per-currency hue so each badge is recognisable at a glance.
    private var tint: Color {
        let seed = option.code.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return Color(hue: Double(seed % 360) / 360, saturation: 0.55, brightness: 0.78)
    }
}

#Preview {
    HStack(spacing: 20) {
        ForEach(["USD", "EUR", "BDT", "JPY", "XAF"], id: \.self) { code in
            CurrencyBadge(option: CurrencyCatalog.shared.option(for: code))
        }
    }
    .padding()
}
