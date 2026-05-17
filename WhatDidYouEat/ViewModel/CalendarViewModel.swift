//
//  CalendarViewModel.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import Foundation

/// 캘린더 월 이동 + 그리드 계산 전담
/// 데이터 로딩은 CalendarView의 @Query가 담당 → SwiftData 변경 자동 감지
@Observable
@MainActor
final class CalendarViewModel {

    // MARK: - State

    var displayYear: Int
    var displayMonth: Int
    var selectedDate: Date? = nil

    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal
    }()

    // MARK: - Init

    init() {
        let now = Date()
        let cal = Calendar.current
        self.displayYear  = cal.component(.year,  from: now)
        self.displayMonth = cal.component(.month, from: now)
    }

    // MARK: - Public

    func goToPreviousMonth() {
        var components = DateComponents()
        components.year  = displayYear
        components.month = displayMonth - 1
        if let date = calendar.date(from: components) {
            displayYear  = calendar.component(.year,  from: date)
            displayMonth = calendar.component(.month, from: date)
        }
    }

    func goToNextMonth() {
        var components = DateComponents()
        components.year  = displayYear
        components.month = displayMonth + 1
        if let date = calendar.date(from: components) {
            displayYear  = calendar.component(.year,  from: date)
            displayMonth = calendar.component(.month, from: date)
        }
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

    func dateKey(for date: Date) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(String(format: "%02d", comps.month ?? 0))-\(String(format: "%02d", comps.day ?? 0))"
    }
}
