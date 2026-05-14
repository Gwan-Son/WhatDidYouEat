//
//  MealRepository.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import Foundation

/// Meal 데이터 접근의 추상화 인터페이스
/// Phase 1: LocalMealRepository (SwiftData)
/// Phase 2: SyncMealRepository (SwiftData + Firestore)
protocol MealRepository {

    /// 특정 날짜의 식사 기록을 모두 가져옴
    func fetchMeals(for date: Date) async -> [Meal]

    /// 특정 달(year, month)의 모든 식사 기록을 가져옴
    func fetchMeals(year: Int, month: Int) async -> [Meal]

    /// 식사 기록 저장
    func save(_ meal: Meal) async throws

    /// 식사 기록 삭제
    func delete(_ meal: Meal) async throws
}
