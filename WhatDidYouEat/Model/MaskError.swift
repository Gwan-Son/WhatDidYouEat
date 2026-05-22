//
//  MaskError.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import Foundation

/// Vision 배경 제거 처리 중 발생할 수 있는 에러
enum MaskError: LocalizedError {

    /// 카메라가 없는 기기 또는 환경
    case cameraUnavailable

    /// 카메라 권한 거부 또는 제한
    case cameraPermissionDenied

    /// 촬영 이미지 획득 실패
    case captureFailed

    /// 갤러리 이미지 로드 실패
    case photoLibraryLoadFailed

    /// UIImage에서 CGImage 변환 실패
    case invalidImage

    /// Vision이 전경 피사체를 감지하지 못함 (음식이 배경과 너무 유사한 경우 등)
    case noSubjectFound

    /// 마스크 생성 실패
    case maskGenerationFailed(Error)

    /// CIFilter 렌더링 실패
    case renderFailed

    /// PNG 데이터 변환 실패
    case pngConversionFailed

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "이 기기에서는 카메라를 사용할 수 없습니다."
        case .cameraPermissionDenied:
            return "카메라 권한이 필요합니다."
        case .captureFailed:
            return "촬영한 사진을 불러오지 못했습니다."
        case .photoLibraryLoadFailed:
            return "선택한 사진을 불러오지 못했습니다."
        case .invalidImage:
            return "이미지를 처리할 수 없습니다."
        case .noSubjectFound:
            return "음식을 인식하지 못했어요. 음식이 잘 보이도록 다시 촬영해 주세요."
        case .maskGenerationFailed(let error):
            return "배경 제거 처리 중 오류가 발생했습니다. (\(error.localizedDescription))"
        case .renderFailed:
            return "이미지 합성에 실패했습니다."
        case .pngConversionFailed:
            return "이미지 저장 형식 변환에 실패했습니다."
        }
    }

    /// 유저에게 보여줄 복구 제안 메시지
    var recoverySuggestion: String? {
        switch self {
        case .cameraUnavailable:
            return "갤러리에서 사진을 선택해 주세요."
        case .cameraPermissionDenied:
            return "설정에서 카메라 접근을 허용한 뒤 다시 시도해 주세요."
        case .captureFailed, .photoLibraryLoadFailed:
            return "다른 사진으로 다시 시도해 주세요."
        case .noSubjectFound:
            return "밝은 배경 위에 음식을 놓고 촬영하면 더 잘 인식돼요."
        default:
            return "다시 시도해 주세요."
        }
    }
}
