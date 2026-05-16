//
//  VisionMaskService.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//
//  [요구사항]
//  - iOS 17+ VNGenerateForegroundInstanceMaskRequest 사용
//  - 음식만 누끼 처리 (식기·젓가락 등 제외 방향이나, Vision은 전경 피사체 전체를 감지함)
//    → 현재: allInstances 사용 (전경 전체 선택)
//    → 추후: CoreML 음식 분류기 연동으로 인스턴스별 음식 여부 필터링 가능
//  - Vision 처리는 백그라운드 스레드에서 실행 (Task.detached)
//  - 결과는 투명 배경 PNG (UIImage)
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - MaskResult

/// Vision 배경 제거 처리 결과
struct MaskResult {
    /// 배경이 제거된 이미지 (투명 배경 PNG 용도)
    let maskedImage: UIImage
    /// 배경이 제거된 이미지의 PNG Data (SwiftData 저장용)
    let maskedImageData: Data
    /// 원본 이미지
    let originalImage: UIImage
}

// MARK: - VisionMaskService

/// Vision 프레임워크를 사용한 음식 배경 제거 서비스
///
/// 사용 예시:
/// ```swift
/// let service = VisionMaskService()
/// do {
///     let result = try await service.removeBackground(from: capturedImage)
///     // result.maskedImage: 누끼 UIImage
///     // result.maskedImageData: SwiftData 저장용 PNG Data
/// } catch let error as MaskError {
///     print(error.errorDescription ?? "")
/// }
/// ```
final class VisionMaskService {

    // CIContext는 재사용 비용이 크므로 한 번만 생성
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - Public API

    /// 이미지에서 전경(음식) 피사체를 추출해 배경을 제거합니다.
    /// - Parameter image: 원본 음식 사진
    /// - Returns: `MaskResult` (누끼 이미지 + Data)
    /// - Throws: `MaskError`
    ///
    /// - Note: `VNGenerateForegroundInstanceMaskRequest`는 Neural Engine이 필요해
    ///         **시뮬레이터에서 동작하지 않습니다.** 실기기(iOS 17+)에서 실행하세요.
    ///         시뮬레이터에서는 원본 이미지를 그대로 반환합니다.
    func removeBackground(from image: UIImage) async throws -> MaskResult {
#if targetEnvironment(simulator)
        // 시뮬레이터: Neural Engine 없음 → 원본 이미지 그대로 반환 (UI 확인용)
        guard let pngData = image.pngData() else { throw MaskError.pngConversionFailed }
        return MaskResult(maskedImage: image, maskedImageData: pngData, originalImage: image)
#else
        // 실기기: Vision으로 배경 제거
        return try await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { throw MaskError.renderFailed }
            return try self.performMasking(on: image)
        }.value
#endif
    }

    // MARK: - Private Core Logic

    private func performMasking(on image: UIImage) throws -> MaskResult {
        guard let cgImage = image.cgImage else {
            throw MaskError.invalidImage
        }

        // 1. Vision 요청 설정
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            throw MaskError.maskGenerationFailed(error)
        }

        // 2. 결과 검증
        guard let observation = request.results?.first else {
            throw MaskError.noSubjectFound
        }

        // 3. 마스크 버퍼 생성
        //    allInstances: 전경에서 감지된 모든 피사체 포함
        //    TODO: CoreML 음식 분류기 연동 후 음식 인스턴스만 선택하도록 개선
        let maskPixelBuffer: CVPixelBuffer
        do {
            maskPixelBuffer = try observation.generateScaledMaskForImage(
                forInstances: observation.allInstances,
                from: handler
            )
        } catch {
            throw MaskError.maskGenerationFailed(error)
        }

        // 4. 마스크 합성 → 투명 배경 이미지 생성
        let maskedImage = try applyMask(maskPixelBuffer, to: cgImage, originalSize: image.size)

        // 5. PNG Data 변환 (투명 배경 보존에 PNG 필수)
        guard let pngData = maskedImage.pngData() else {
            throw MaskError.pngConversionFailed
        }

        return MaskResult(
            maskedImage: maskedImage,
            maskedImageData: pngData,
            originalImage: image
        )
    }

    // MARK: - Mask Compositing

    /// CVPixelBuffer 마스크를 원본 CGImage에 합성해 투명 배경 UIImage 반환
    private func applyMask(_ mask: CVPixelBuffer, to cgImage: CGImage, originalSize: CGSize) throws -> UIImage {
        let maskCIImage = CIImage(cvPixelBuffer: mask)
        let sourceCIImage = CIImage(cgImage: cgImage)

        // CIBlendWithMask: source * mask → 마스크가 흰 영역만 남고 나머지는 투명
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = sourceCIImage
        blendFilter.maskImage = maskCIImage
        blendFilter.backgroundImage = CIImage.empty() // 투명 배경

        guard
            let outputCIImage = blendFilter.outputImage,
            let outputCGImage = ciContext.createCGImage(outputCIImage, from: sourceCIImage.extent)
        else {
            throw MaskError.renderFailed
        }

        // scale/orientation 유지
        return UIImage(cgImage: outputCGImage, scale: 1.0, orientation: .up)
    }
}
