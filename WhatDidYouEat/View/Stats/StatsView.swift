//
//  StatsView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/20/26.
//

import SwiftUI
import SwiftData

// MARK: - StatsView

struct StatsView: View {

    @Query private var recentMeals: [Meal]

    private let calendar = Calendar.current
    private let statsStartDate: Date

    init() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        let start = calendar.date(byAdding: .year, value: -1, to: today) ?? today
        self.statsStartDate = start

        _recentMeals = Query(
            filter: #Predicate<Meal> { meal in
                meal.date >= start && meal.date < tomorrow
            },
            sort: \.date
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: 요약 카드
                summarySection

                // MARK: 잔디 히트맵
                heatmapSection

                // MARK: 월별 막대그래프
                monthlyBarSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("통계")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - 요약 카드

    @ViewBuilder
    private var summarySection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "최근 1년 기록",
                value: "\(recentMeals.count)",
                unit: "개",
                icon: "fork.knife.circle.fill",
                color: .orange
            )
            StatCard(
                title: "기록한 날",
                value: "\(recordedDaysCount)",
                unit: "일",
                icon: "calendar.badge.checkmark",
                color: .green
            )
            StatCard(
                title: "현재 연속",
                value: "\(currentStreak)",
                unit: "일",
                icon: "flame.fill",
                color: currentStreak > 0 ? .red : .secondary
            )
            StatCard(
                title: "최장 연속",
                value: "\(longestStreak)",
                unit: "일",
                icon: "trophy.fill",
                color: .yellow
            )
        }
    }

    // MARK: - 잔디 히트맵

    @ViewBuilder
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("기록 히트맵")
                    .font(.headline)
                Spacer()
                Text("올해")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 4) {
                    // 요일 레이블 — 고정 (월 레이블 높이만큼 상단 여백)
                    VStack(spacing: 0) {
                        Color.clear.frame(width: 12, height: 16) // width 고정: VStack 팽창 방지
                        weekdayLabelColumn
                    }

                    // 단일 ScrollView: 월 레이블 + 잔디 그리드 동기화 스크롤
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            monthLabelsRow
                            heatmapGrid
                        }
                        // 오른쪽 잔디 셀이 카드 모서리에 걸리지 않도록 trailing 여백
                        .padding(.trailing, 8)
                    }
                }

                legendRow
            }
            .padding(16)
            // clipShape 대신 cornerRadius 사용 → ScrollView 콘텐츠가 모서리에서 잘리지 않음
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
    }

    // MARK: Heatmap 계산

    /// 올해 1월 1일 ~ 오늘을 주(week) 단위 컬럼으로 구성
    private var weekColumns: [[Date?]] {
        let today = calendar.startOfDay(for: Date())
        let year  = calendar.component(.year, from: today)

        // 올해 1월 1일
        guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else { return [] }

        // start를 해당 주의 일요일로 맞춤
        let startWeekday = calendar.component(.weekday, from: start) // 1=Sun
        let offset = startWeekday - 1
        guard let gridStart = calendar.date(byAdding: .day, value: -offset, to: start) else { return [] }

        var columns: [[Date?]] = []
        var current = gridStart

        while current <= today {
            var week: [Date?] = []
            for _ in 0..<7 {
                if current > today || current < start {
                    week.append(nil)
                } else {
                    week.append(current)
                }
                current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
            }
            columns.append(week)
        }
        return columns
    }

    /// 날짜별 식사 수 딕셔너리
    private var mealCountByDate: [String: Int] {
        var counts: [String: Int] = [:]
        for meal in recentMeals {
            let key = dateKey(meal.date)
            counts[key, default: 0] += 1
        }
        return counts
    }

    private func mealCount(for date: Date) -> Int {
        mealCountByDate[dateKey(date)] ?? 0
    }

    private func dateKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }

    /// 잔디 색상 (식사 수에 따른 오렌지 농도)
    private func cellColor(count: Int) -> Color {
        switch count {
        case 0:         return Color(.systemGray5)
        case 1:         return Color.orange.opacity(0.3)
        case 2:         return Color.orange.opacity(0.6)
        case 3:         return Color.orange.opacity(0.85)
        default:        return Color.orange
        }
    }

    // MARK: Heatmap 서브뷰

    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 3

    @ViewBuilder
    private var heatmapGrid: some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            ForEach(Array(weekColumns.enumerated()), id: \.offset) { _, week in
                VStack(spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        if let date = week[dayIndex] {
                            let count = mealCount(for: date)
                            let isToday = calendar.isDateInToday(date)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(cellColor(count: count))
                                .frame(width: cellSize, height: cellSize)
                                // 오늘 날짜에 오렌지 테두리 시표
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.orange, lineWidth: isToday ? 1.5 : 0)
                                )
                        } else {
                            // 범위 밖(시작 전) 또는 미래 날짜 → 투명 (구조 유지)
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var weekdayLabelColumn: some View {
        VStack(spacing: cellSpacing) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { label in
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .frame(width: 12, height: cellSize)
            }
        }
    }

    /// 월 레이블 행 — ScrollView 없이 순수 HStack 반환 (상위 ScrollView와 동기화)
    @ViewBuilder
    private var monthLabelsRow: some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            ForEach(Array(weekColumns.enumerated()), id: \.offset) { _, week in
                let label = monthLabel(for: week)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(label.isEmpty ? .clear : .secondary)
                    .frame(width: cellSize + cellSpacing, alignment: .leading)
            }
        }
    }

    /// 주 안에 1일이 포함된 경우 해당 월 레이블 반환
    /// (day <= 7 조건은 월 시작이 일요일이 아단 경우 1주 늦게 표시되는 버그 발생)
    private func monthLabel(for week: [Date?]) -> String {
        for date in week.compactMap({ $0 }) {
            if calendar.component(.day, from: date) == 1 {
                return "\(calendar.component(.month, from: date))월"
            }
        }
        return ""
    }

    @ViewBuilder
    private var legendRow: some View {
        HStack(spacing: 4) {
            Text("적음")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            ForEach([0, 1, 2, 3, 4], id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(cellColor(count: level))
                    .frame(width: cellSize, height: cellSize)
            }
            Text("많음")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    // MARK: - 월별 막대그래프

    @ViewBuilder
    private var monthlyBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("월별 기록")
                .font(.headline)

            VStack(spacing: 0) {
                let data = last6MonthsData
                let maxCount = data.map(\.count).max() ?? 1

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data, id: \.label) { item in
                        VStack(spacing: 6) {
                            if item.count > 0 {
                                Text("\(item.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.orange)
                            }

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    item.isCurrentMonth
                                    ? Color.orange
                                    : Color.orange.opacity(0.35)
                                )
                                .frame(
                                    height: max(4, CGFloat(item.count) / CGFloat(maxCount) * 120)
                                )
                                .animation(.easeOut(duration: 0.4), value: item.count)

                            Text(item.label)
                                .font(.system(size: 10))
                                .foregroundStyle(item.isCurrentMonth ? .orange : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 160, alignment: .bottom)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - 통계 계산

    private var recordedDaysCount: Int {
        Set(recentMeals.map { dateKey($0.date) }).count
    }

    private var currentStreak: Int {
        var streak = 0
        var day = calendar.startOfDay(for: Date())
        while mealCountByDate[dateKey(day), default: 0] > 0 {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }

    private var longestStreak: Int {
        guard !recentMeals.isEmpty else { return 0 }

        let recordedDates = Set(recentMeals.map { calendar.startOfDay(for: $0.date) })
            .sorted()

        var longest = 1
        var current = 1

        for i in 1..<recordedDates.count {
            let diff = calendar.dateComponents([.day],
                from: recordedDates[i - 1],
                to: recordedDates[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else if diff > 1 {
                current = 1
            }
        }
        return longest
    }

    struct MonthData {
        let label: String
        let count: Int
        let isCurrentMonth: Bool
    }

    private var last6MonthsData: [MonthData] {
        let now = Date()
        return (0...5).reversed().map { offset -> MonthData in
            guard let target = calendar.date(byAdding: .month, value: -offset, to: now) else {
                return MonthData(label: "", count: 0, isCurrentMonth: false)
            }
            let y = calendar.component(.year,  from: target)
            let m = calendar.component(.month, from: target)
            let count = recentMeals.filter {
                calendar.component(.year,  from: $0.date) == y &&
                calendar.component(.month, from: $0.date) == m
            }.count
            let label = "\(m)월"
            let isCurrent = offset == 0
            return MonthData(label: label, count: count, isCurrentMonth: isCurrent)
        }
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StatsView()
    }
    .modelContainer(for: Meal.self, inMemory: true)
}
