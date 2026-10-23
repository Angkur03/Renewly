//
// BadgeView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

struct BadgeView: View {
    let text: Text
    let systemImage: String?
    let tint: Color
    private var isCompact = false

    init(_ key: LocalizedStringKey, systemImage: String? = nil, tint: Color = .accentColor) {
        self.text = Text(key)
        self.systemImage = systemImage
        self.tint = tint
    }

    @_disfavoredOverload
    init(_ text: String, systemImage: String? = nil, tint: Color = .accentColor) {
        self.text = Text(text)
        self.systemImage = systemImage
        self.tint = tint
    }

    /// Shows only the icon when space is tight. VoiceOver still reads the text.
    func compact(_ isCompact: Bool = true) -> BadgeView {
        var copy = self
        copy.isCompact = isCompact && systemImage != nil
        return copy
    }

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
            }
            if !isCompact {
                text.lineLimit(1)
            }
        }
        .appFont(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.14), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.25), lineWidth: 0.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

#Preview {
    HStack {
        BadgeView("Subscription", systemImage: "arrow.triangle.2.circlepath")
        BadgeView("3 days left", systemImage: "clock", tint: .orange)
        BadgeView("Expired", tint: .red)
        BadgeView("Alerts", systemImage: "bell.fill", tint: .indigo).compact()
    }
    .padding()
}
