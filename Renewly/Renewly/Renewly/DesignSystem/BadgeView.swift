//
// BadgeView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

struct BadgeView: View {
    let text: String
    let systemImage: String?
    let tint: Color

    init(_ text: String, systemImage: String? = nil, tint: Color = .accentColor) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
            }
            Text(text)
        }
        .vaultFont(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.14), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.25), lineWidth: 0.5))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        BadgeView("Subscription", systemImage: "arrow.triangle.2.circlepath")
        BadgeView("3 days left", systemImage: "clock", tint: .orange)
        BadgeView("Expired", tint: .red)
    }
    .padding()
}
