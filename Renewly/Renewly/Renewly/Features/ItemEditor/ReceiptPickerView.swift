//
// ReceiptPickerView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import PhotosUI
import SwiftUI
import UIKit

struct ReceiptPickerView: View {
    let previewData: Data?
    let onPick: (Data) -> Void
    let onRemove: () -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var isCameraPresented = false
    @State private var loadFailed = false

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            preview

            HStack(spacing: 10) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Library", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)

                Button {
                    isCameraPresented = true
                } label: {
                    Label("Camera", systemImage: "camera")
                }
                .buttonStyle(.bordered)
                .disabled(!isCameraAvailable)

                if previewData != nil {
                    Spacer()
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Remove receipt")
                }
            }
            .appFont(.subheadline)

            if loadFailed {
                Text("That photo could not be loaded. Try another one.")
                    .appFont(.caption)
                    .foregroundStyle(.red)
            }
        }
        .task(id: pickerItem) {
            await loadPickedPhoto()
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker(onCapture: onPick)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let previewData, let image = UIImage(data: previewData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
                .accessibilityLabel("Receipt preview")
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.quaternary)
                .frame(height: 120)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.title)
                        Text("Attach a receipt or warranty card")
                            .appFont(.footnote)
                    }
                    .foregroundStyle(.secondary)
                }
        }
    }

    private func loadPickedPhoto() async {
        guard let pickerItem else { return }
        loadFailed = false
        do {
            if let data = try await pickerItem.loadTransferable(type: Data.self) {
                onPick(data)
            } else {
                loadFailed = true
            }
        } catch {
            loadFailed = true
        }
        self.pickerItem = nil
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: { dismiss() })
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (Data) -> Void
        private let dismiss: () -> Void

        init(onCapture: @escaping (Data) -> Void, dismiss: @escaping () -> Void) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.9) {
                onCapture(data)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

#Preview {
    Form {
        Section("Receipt") {
            ReceiptPickerView(previewData: nil, onPick: { _ in }, onRemove: {})
        }
    }
}
