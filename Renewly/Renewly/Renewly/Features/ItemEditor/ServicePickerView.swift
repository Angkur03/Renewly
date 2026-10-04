//
// ServicePickerView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

struct ServicePickerView: View {
    var catalog: ServiceCatalog = .shared
    let onSelect: (ServiceTemplate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    ForEach(catalog.groups, id: \.group) { entry in
                        Section(entry.group.title) {
                            ForEach(entry.services) { service in
                                row(for: service)
                            }
                        }
                    }
                } else {
                    let results = catalog.search(query)
                    if results.isEmpty {
                        ContentUnavailableView {
                            Label("Not in the list", systemImage: "magnifyingglass")
                        } description: {
                            Text("Close this and type the name yourself. Any service can be tracked.")
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(results) { service in
                            row(for: service)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search services")
            .navigationTitle("Popular services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func row(for service: ServiceTemplate) -> some View {
        Button {
            onSelect(service)
            dismiss()
        } label: {
            ServiceRow(service: service)
        }
        .buttonStyle(.plain)
    }
}

struct ServiceRow: View {
    let service: ServiceTemplate

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: service.group.systemImage)
                .font(.callout)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .appFont(.body)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        service.manageURL == nil ? service.billingCycle.title : "\(service.billingCycle.title) · cancel link included"
    }
}

#Preview("Browse") {
    ServicePickerView { _ in }
}

#Preview("Few services") {
    ServicePickerView(catalog: ServiceCatalog(services: Array(ServiceCatalog.builtIn.prefix(3)))) { _ in }
}
