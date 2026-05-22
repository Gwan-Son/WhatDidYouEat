//
//  ImagePickerView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI
import PhotosUI

/// 갤러리에서 이미지를 선택하는 PHPickerViewController 래퍼
struct ImagePickerView: UIViewControllerRepresentable {

    /// 선택된 이미지를 전달할 클로저
    let onImageSelected: (UIImage) -> Void
    let onCancel: () -> Void
    let onLoadFailed: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onImageSelected: onImageSelected,
            onCancel: onCancel,
            onLoadFailed: onLoadFailed
        )
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        let onCancel: () -> Void
        let onLoadFailed: () -> Void

        init(
            onImageSelected: @escaping (UIImage) -> Void,
            onCancel: @escaping () -> Void,
            onLoadFailed: @escaping () -> Void
        ) {
            self.onImageSelected = onImageSelected
            self.onCancel = onCancel
            self.onLoadFailed = onLoadFailed
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                DispatchQueue.main.async { [weak self] in
                    self?.onCancel()
                }
                return
            }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.onImageSelected(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.onLoadFailed()
                    }
                }
            }
        }
    }
}
