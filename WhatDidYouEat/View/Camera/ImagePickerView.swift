//
//  ImagePickerView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI
import PhotosUI

/// 갤러리에서 이미지를 선택하는 PHPickerViewController 래퍼
///
/// PHPickerViewController를 UINavigationController에 embed해 반환합니다.
/// SwiftUI sheet 내부에서 발생하는 UIKit 내부 AutoLayout 경고를 완화하는
/// 알려진 workaround입니다. (Apple 내부 버그 — 기능에는 영향 없음)
struct ImagePickerView: UIViewControllerRepresentable {

    /// 선택된 이미지를 전달할 클로저
    let onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator

        // UINavigationController로 감싸 SwiftUI sheet과의 constraint 충돌 완화
        let nav = UINavigationController(rootViewController: picker)
        nav.setNavigationBarHidden(true, animated: false)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void

        init(onImageSelected: @escaping (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let result = results.first else { return }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.onImageSelected(image)
                    }
                }
            }
        }
    }
}
