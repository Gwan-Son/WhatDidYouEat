//
//  CalendarViewModel.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import Foundation

@Observable
@MainActor
final class CalendarViewModel {

    // MARK: - State

    /// 현재 표시 중인 연도
    var displayYear: Int
    /// 현재 표시 중인 월 (1~12)
    var displayMonth: Int
    /// 날짜별 식사 기록 캐시  key: "yyyy-MM-dd"
    var mealsByDate: [String: [Meal]] = [:]
    /// 상세 뷰로 이동할 선택된 날짜
    var selectedDate: Date? = nil
    /// 데이터 로딩 상태
    var isLoading: Bool = false

    private let repository: any MealRepository
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 1  // 일요일 시작
        return cal
    }()

    // MARK: - Init

    init(repository: any MealRepository) {
        let now = Date()
        let cal = Calendar.current
        self.displayYear  = cal.component(.year,  from: now)
        self.displayMonth = cal.component(.month, from: now)
        self.repository   = repository
    }

    // MARK: - Public

    /// 이전 달로 이동
    func goToPreviousMonth() {
        var components = DateComponents()
        components.year  = displayYear
        components.month = displayMonth - 1

        if let date = calendar.date(from: components) {
            displayYear  = calendar.component(.year,  from: date)
            displayMonth = calendar.component(.month, from: date)
            Task { await loadMeals() }
        }
    }

    /// 다음 달로 이동
    func goToNextMonth() {
        var components = DateComponents()
        components.year  = displayYear
        components.month = displayMonth + 1

        if let date = calendar.date(from: components) {
            displayYear  = calendar.component(.year,  from: date)
            displayMonth = calendar.component(.month, from: date)
            Task { await loadMeals() }
        }
    }

    /// 현재 displayYear/displayMonth의 식사 기록을 로드
    func loadMeals() async {
        isLoading = true
        let meals = await repository.fetchMeals(year: displayYear, month: displayMonth)

        // 날짜별로 그룹핑
        var grouped: [String: [Meal]] = [:]
        for meal in meals {
            let key = dateKey(for: meal.date)
            grouped[key, default: []].append(meal)
        }
        mealsByDate = grouped
        isLoading = false
    }

    /// 특정 날짜의 식사 목록 반환
    func meals(for date: Date) -> [Meal] {
        mealsByDate[dateKey(for: date)] ?? []
    }

    // MARK: - Calendar Grid

    /// 캘린더 그리드에 표시할 날짜 배열 (월 시작 전 nil 패딩 포함)
    func calendarDays() -> [Date?] {
        var comps = DateComponents()
        comps.year  = displayYear
        comps.month = displayMonth
        comps.day   = 1

        guard let firstDay = calendar.date(from: comps) else { return [] }

        // 주의 첫 번째 날(일요일=1) 기준 오프셋
        let weekday = calendar.component(.weekday, from: firstDay)
        let offset  = weekday - calendar.firstWeekday

        // 월의 일수
        guard let range = calendar.range(of: .day, in: .month, for: firstDay) else { return [] }

        var days: [Date?] = Array(repeating: nil, count: offset < 0 ? offset + 7 : offset)

        for day in range {
            var dc = DateComponents()
            dc.year  = displayYear
            dc.month = displayMonth
            dc.day   = day
            days.append(calendar.date(from: dc))
        }

        // 7의 배수로 패딩
        while days.count % 7 != 0 { days.append(nil) }

        return days
    }

    /// 오늘인지 확인
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// 표시 중인 달의 제목 (예: "2026년 5월")
    var monthTitle: String {
        "\(displayYear)년 \(displayMonth)월"
    }

    // MARK: - Private

    private func dateKey(for date: Date) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(String(format: "%02d", comps.month ?? 0))-\(String(format: "%02d", comps.day ?? 0))"
    }
}
