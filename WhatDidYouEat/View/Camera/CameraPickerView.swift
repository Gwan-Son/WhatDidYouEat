//
//  CameraPickerView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI
import UIKit

/// 카메라로 직접 촬영하는 UIImagePickerController 래퍼
struct CameraPickerView: UIViewControllerRepresentable {

    /// 촬영된 이미지를 전달할 클로저
    let onImageCaptured: (UIImage) -> Void
    let onCancel: () -> Void
    let onCaptureFailed: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onImageCaptured: onImageCaptured,
            onCancel: onCancel,
            onCaptureFailed: onCaptureFailed
        )
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject,
                              UIImagePickerControllerDelegate,
                              UINavigationControllerDelegate {

        let onImageCaptured: (UIImage) -> Void
        let onCancel: () -> Void
        let onCaptureFailed: () -> Void

        init(
            onImageCaptured: @escaping (UIImage) -> Void,
            onCancel: @escaping () -> Void,
            onCaptureFailed: @escaping () -> Void
        ) {
            self.onImageCaptured = onImageCaptured
            self.onCancel = onCancel
            self.onCaptureFailed = onCaptureFailed
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            } else {
                onCaptureFailed()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
