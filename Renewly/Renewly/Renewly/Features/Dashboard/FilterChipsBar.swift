//
// FilterChipsBar.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

struct FilterChipsBar: View {
    @Binding var selection: DashboardFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DashboardFilter.allCases) { filter in
                    chip(for: filter)
                }
            }
            .padding(.vertical, 2)
        }
        .rigidHaptic(trigger: selection)
    }

    private func chip(for filter: DashboardFilter) -> some View {
        let isSelected = filter == selection
        return Button {
            withAnimation(.snappy) {
                selection = filter
            }
        } label: {
            Text(filter.title)
                .vaultFont(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background {
                    if isSelected {
                        Capsule().fill(Color.accentColor)
                    } else {
                        Capsule().fill(.ultraThinMaterial)
                    }
                }
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var filter: DashboardFilter = .all
    FilterChipsBar(selection: $filter)
        .padding()
}
