//
//  CameraViewModel.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI

// MARK: - State Machine

extension CameraViewModel {
    enum CameraState: Equatable {
        /// 이미지 선택 대기 중
        case idle
        /// Vision 처리 중
        case processing
        /// 누끼 결과 확인 중
        case preview(MaskResult)
        /// 저장 중
        case saving
        /// 저장 완료
        case saved
        /// 에러
        case error(MaskError)

        static func == (lhs: CameraState, rhs: CameraState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.processing, .processing),
                 (.saving, .saving), (.saved, .saved): return true
            case (.preview, .preview): return true
            case (.error, .error): return true
            default: return false
            }
        }
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class CameraViewModel {

    // MARK: State

    var cameraState: CameraState = .idle

    /// 음식 이름 입력 (선택)
    var mealName: String = ""
    /// 메모 입력 (선택)
    var memo: String = ""
    /// 먹은 날짜 (기본: 오늘)
    var mealDate: Date = Date()
    /// 누끼 대신 원본 이미지 저장 여부
    var useOriginalImage: Bool = false
    /// 저장 전 이미지 확대/축소
    var stickerScale: Double = 1.0
    /// 저장 전 이미지 회전 각도
    var stickerRotation: Double = 0

    // MARK: Sheet Presentation

    var showingImagePicker: Bool = false
    var showingCameraPicker: Bool = false

    // MARK: Computed

    var maskResult: MaskResult? {
        guard case .preview(let result) = cameraState else { return nil }
        return result
    }

    var previewImage: UIImage? {
        guard let result = maskResult else { return nil }
        return useOriginalImage ? result.originalImage : result.maskedImage
    }

    var isShowingPreview: Bool {
        if case .preview = cameraState { return true }
        if cameraState == .saving || cameraState == .saved { return true }
        return false
    }

    var currentError: MaskError? {
        guard case .error(let error) = cameraState else { return nil }
        return error
    }

    // MARK: Dependencies

    private let maskService = VisionMaskService()
    private let repository: any MealRepository

    init(repository: any MealRepository) {
        self.repository = repository
    }

    // MARK: - Actions

    func showError(_ error: MaskError) {
        cameraState = .error(error)
    }

    /// 이미지를 받아 Vision 배경 제거를 실행합니다.
    func processImage(_ image: UIImage) async {
        cameraState = .processing

        do {
            let result = try await maskService.removeBackground(from: image)
            cameraState = .preview(result)
        } catch let error as MaskError {
            cameraState = .error(error)
        } catch {
            cameraState = .error(.renderFailed)
        }
    }

    /// 누끼 결과를 SwiftData에 저장합니다.
    func saveMeal() async {
        guard let result = maskResult else { return }

        cameraState = .saving

        let meal = Meal(
            date: mealDate,
            originalImageData: result.originalImage.jpegData(compressionQuality: 0.8),
            maskedImageData: editedImageData(from: result),
            name: mealName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : mealName,
            memo: memo.trimmingCharacters(in: .whitespaces).isEmpty ? nil : memo
        )

        do {
            try await repository.save(meal)
            cameraState = .saved
        } catch {
            cameraState = .error(.renderFailed)
        }
    }

    /// 처음 상태로 돌아갑니다. (다시 찍기 / 저장 완료 후 초기화)
    func reset() {
        cameraState = .idle
        mealName = ""
        memo = ""
        mealDate = Date()
        useOriginalImage = false
        stickerScale = 1.0
        stickerRotation = 0
    }

    private func editedImageData(from result: MaskResult) -> Data {
        let sourceImage = useOriginalImage ? result.originalImage : result.maskedImage
        let editedImage = renderEditedImage(sourceImage)
        return editedImage.pngData() ?? result.maskedImageData
    }

    private func renderEditedImage(_ image: UIImage) -> UIImage {
        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.opaque = false
        rendererFormat.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: image.size, format: rendererFormat)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: image.size.width / 2, y: image.size.height / 2)
            cgContext.rotate(by: CGFloat(stickerRotation * .pi / 180))
            cgContext.scaleBy(x: stickerScale, y: stickerScale)

            let drawRect = CGRect(
                x: -image.size.width / 2,
                y: -image.size.height / 2,
                width: image.size.width,
                height: image.size.height
            )
            image.draw(in: drawRect)
        }
    }
}
