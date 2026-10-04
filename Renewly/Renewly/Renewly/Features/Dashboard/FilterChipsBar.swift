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
    var counts: [DashboardFilter: Int] = [:]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DashboardFilter.allCases) { filter in
                    chip(for: filter)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
        .rigidHaptic(trigger: selection)
    }

    private func chip(for filter: DashboardFilter) -> some View {
        let isSelected = filter == selection
        return Button {
            withAnimation(.snappy) {
                selection = filter
            }
        } label: {
            HStack(spacing: 6) {
                Text(filter.title)
                    .appFont(.subheadline)
                    .fontWeight(.semibold)
                if let count = counts[filter] {
                    Text(count, format: .number)
                        .appFont(.caption)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(
                            (isSelected ? Color.white.opacity(0.25) : Color.secondary.opacity(0.15)),
                            in: Capsule()
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .chipSurface(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(counts[filter].map { "\(filter.title), \($0)" } ?? filter.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("With counts") {
    @Previewable @State var filter: DashboardFilter = .all
    FilterChipsBar(selection: $filter, counts: [.all: 6, .subscriptions: 3, .warranties: 3, .expiringSoon: 1])
        .padding()
}

#Preview("No counts") {
    @Previewable @State var filter: DashboardFilter = .warranties
    FilterChipsBar(selection: $filter)
        .padding()
}
