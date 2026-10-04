//
// BackupSection.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Settings rows to save every item and receipt to a file, and to restore from one.
struct BackupSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [TrackedItem]
    @State private var viewModel: BackupViewModel

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: BackupViewModel(dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Section {
            Button {
                Task { await viewModel.exportBackup(items: items) }
            } label: {
                row("Export Backup", systemImage: "square.and.arrow.up", detail: exportDetail)
            }
            .disabled(items.isEmpty || viewModel.isWorking)

            Button {
                viewModel.isImporterPresented = true
            } label: {
                row("Restore from Backup", systemImage: "arrow.counterclockwise.icloud", detail: nil)
            }
            .disabled(viewModel.isWorking)
        } header: {
            Text("Backup")
        } footer: {
            Text("Saves every item and receipt photo to one file. Store it in iCloud Drive or Files to move to a new iPhone. Restoring only adds items, it never deletes or overwrites.")
        }
        .fileExporter(
            isPresented: $viewModel.isExporterPresented,
            document: viewModel.exportFile,
            contentType: .json,
            defaultFilename: viewModel.exportFilename
        ) { result in
            viewModel.exportFinished(result)
        }
        .fileImporter(isPresented: $viewModel.isImporterPresented, allowedContentTypes: [.json]) { result in
            Task { await viewModel.importFinished(result, into: modelContext) }
        }
        .errorAlert(message: $viewModel.errorMessage)
        .alert(
            "Backup",
            isPresented: Binding(
                get: { viewModel.statusMessage != nil },
                set: { if !$0 { viewModel.statusMessage = nil } }
            ),
            presenting: viewModel.statusMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private var exportDetail: String {
        items.isEmpty ? "Nothing to back up yet" : ExpiryText.count(items.count, "item")
    }

    private func row(_ title: String, systemImage: String, detail: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(Color.primary)
                if let detail {
                    Text(detail)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 36)
                }
            }
            Spacer()
            if viewModel.isWorking {
                ProgressView()
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    Form {
        BackupSection(dependencies: PreviewData.dependencies())
    }
    .modelContainer(PreviewData.container(populated: true))
}
