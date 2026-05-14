//
//  Meal.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import Foundation
import SwiftData

/// 한 끼 식사 기록을 나타내는 SwiftData 모델
@Model
final class Meal {

    // MARK: - Core Properties

    var id: UUID
    /// 음식을 먹은 날짜 (캘린더 표시 기준)
    var date: Date
    /// 원본 사진 데이터 (선택 저장)
    var originalImageData: Data?
    /// Vision으로 배경 제거된 PNG 데이터 (투명 배경)
    var maskedImageData: Data
    /// 음식 이름 (선택 입력)
    var name: String?
    /// 메모 (선택 입력)
    var memo: String?
    var createdAt: Date

    // MARK: - Phase 2 Extensions (Cloud Sync)

    /// Firestore document ID (Phase 2에서 사용)
    var remoteId: String?
    /// 속한 그룹 ID (Phase 2에서 사용)
    var groupId: String?

    // MARK: - Init

    init(
        id: UUID = UUID(),
        date: Date,
        originalImageData: Data? = nil,
        maskedImageData: Data,
        name: String? = nil,
        memo: String? = nil,
        createdAt: Date = Date(),
        remoteId: String? = nil,
        groupId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.originalImageData = originalImageData
        self.maskedImageData = maskedImageData
        self.name = name
        self.memo = memo
        self.createdAt = createdAt
        self.remoteId = remoteId
        self.groupId = groupId
    }
}
