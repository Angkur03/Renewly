//
// BackupViewModel.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class BackupViewModel {
    var isExporterPresented = false
    var isImporterPresented = false
    var errorMessage: String?
    /// Result of the last export or restore, shown in an alert.
    var statusMessage: String?

    private(set) var exportFile: BackupFile?
    private(set) var exportFilename = BackupCoder.defaultFilename(for: .now)
    private(set) var isWorking = false

    @ObservationIgnored private let service: BackupService
    @ObservationIgnored private let notifications: any NotificationScheduling
    @ObservationIgnored private let entitlements: any EntitlementProviding
    @ObservationIgnored private let now: () -> Date

    init(dependencies: AppDependencies, now: @escaping () -> Date = { .now }) {
        service = BackupService(receipts: dependencies.receipts)
        notifications = dependencies.notifications
        entitlements = dependencies.entitlements
        self.now = now
    }

    func exportBackup(items: [TrackedItem]) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        let archive = await service.makeArchive(from: items, now: now())
        do {
            exportFile = BackupFile(data: try await BackupCoder.encodeInBackground(archive))
            exportFilename = BackupCoder.defaultFilename(for: archive.exportedAt)
            isExporterPresented = true
        } catch {
            errorMessage = error.userMessage
        }
    }

    func exportFinished(_ result: Result<URL, any Error>) {
        exportFile = nil
        switch result {
        case .success:
            statusMessage = "Backup saved. Keep it somewhere safe, like iCloud Drive, to restore on a new iPhone."
        case .failure(let error as CocoaError) where error.code == .userCancelled:
            break
        case .failure:
            errorMessage = "The backup could not be saved there. Try another location."
        }
    }

    func importFinished(_ result: Result<URL, any Error>, into context: ModelContext) async {
        switch result {
        case .success(let url):
            await restore(from: url, into: context)
        case .failure(let error as CocoaError) where error.code == .userCancelled:
            break
        case .failure:
            errorMessage = BackupError.unreadableFile.userMessage
        }
    }

    func restore(from url: URL, into context: ModelContext) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        let summary: RestoreSummary
        do {
            let archive = try await BackupCoder.readArchive(from: url)
            summary = try await service.restore(archive, into: context)
        } catch {
            errorMessage = error.userMessage
            return
        }
        _ = RenewalRolloverService().rollForward(in: context, now: now())
        _ = await ReminderSyncService(notifications: notifications).resync(isPro: entitlements.isPro, in: context)
        statusMessage = summary.message
    }
}
