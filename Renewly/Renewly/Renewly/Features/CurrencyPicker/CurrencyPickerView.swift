//
// CurrencyPickerView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

struct CurrencyPickerView: View {
    let title: String
    @Binding var selection: String

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CurrencyPickerViewModel

    init(title: String, selection: Binding<String>) {
        self.title = title
        _selection = selection
        _viewModel = State(initialValue: CurrencyPickerViewModel(selectedCode: selection.wrappedValue))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        let results = viewModel.results

        NavigationStack {
            List {
                if !viewModel.suggestions.isEmpty {
                    Section("Suggested") {
                        ForEach(viewModel.suggestions) { row(for: $0) }
                    }
                }
                if !results.isEmpty {
                    Section {
                        ForEach(results) { row(for: $0) }
                    } header: {
                        Text(viewModel.resultsTitle)
                    } footer: {
                        if viewModel.isSearching {
                            Text("\(results.count) match\(results.count == 1 ? "" : "es")")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Name, code or symbol"
            )
            .autocorrectionDisabled()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func row(for option: CurrencyOption) -> some View {
        let isSelected = option.code == selection
        return Button {
            selection = option.code
            dismiss()
        } label: {
            CurrencyRow(option: option, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct CurrencyRow: View {
    let option: CurrencyOption
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            CurrencyBadge(option: option, size: 38)
                .padding(.trailing, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(option.name)
                    .vaultFont(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(option.symbol == option.code ? option.code : "\(option.code) · \(option.symbol)")
                    .vaultFont(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(option.name), \(option.code)")
    }
}

/// Form row that shows the current currency and opens the searchable picker.
struct CurrencyField: View {
    let title: String
    @Binding var selection: String

    @State private var isPickerPresented = false

    var body: some View {
        let option = CurrencyCatalog.shared.option(for: selection)
        Button {
            isPickerPresented = true
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                CurrencyBadge(option: option, size: 28)
                    .padding(.trailing, 4)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(option.code)
                        .vaultFont(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(option.name)
                        .vaultFont(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(option.name)")
        .accessibilityHint("Opens a searchable list of currencies")
        .sheet(isPresented: $isPickerPresented) {
            CurrencyPickerView(title: title, selection: $selection)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview("Picker") {
    @Previewable @State var code = "BDT"
    CurrencyPickerView(title: "Currency", selection: $code)
}

#Preview("Field") {
    @Previewable @State var code = "EUR"
    Form {
        CurrencyField(title: "Currency", selection: $code)
    }
}
