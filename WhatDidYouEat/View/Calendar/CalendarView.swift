//
//  CalendarView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI
import SwiftData

/// 월간 캘린더 메인 뷰 — 날짜별 음식 누끼 스티커 표시
struct CalendarView: View {

    @State private var viewModel = CalendarViewModel()

    /// SwiftData 변경 시 자동 갱신 트리거
    @Query(sort: \Meal.date) private var allMeals: [Meal]

    // 7콜럼 그리드
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    /// 현재 표시 월 식사 데이터 (바로 @Query 결과에서 필터/그룹핑)
    private var mealsByDate: [String: [Meal]] {
        let cal = Calendar.current
        let filtered = allMeals.filter {
            cal.component(.year,  from: $0.date) == viewModel.displayYear &&
            cal.component(.month, from: $0.date) == viewModel.displayMonth
        }
        return Dictionary(grouping: filtered) { viewModel.dateKey(for: $0.date) }
    }

    private func mealsForDate(_ date: Date) -> [Meal] {
        mealsByDate[viewModel.dateKey(for: date)] ?? []
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    monthHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    weekdayHeader
                    Divider()

                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(Array(viewModel.calendarDays().enumerated()), id: \.offset) { _, date in
                            if let date {
                                dayCellButton(date: date)
                            } else {
                                Color.clear.frame(height: cellHeight)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .navigationTitle("WhatDidYouEat")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(
            item: Binding(
                get: { viewModel.selectedDate },
                set: { viewModel.selectedDate = $0 }
            )
        ) { date in
            DayDetailView(date: date)
        }
    }

    // MARK: - Cell Height

    private var cellHeight: CGFloat { 90 }

    // MARK: - Month Header

    @ViewBuilder
    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.goToPreviousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(.title2.bold())
                .contentTransition(.numericText())

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.goToNextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Weekday Header

    @ViewBuilder
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .foregroundStyle(day == "일" ? .red : day == "토" ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Day Cell Button

    @ViewBuilder
    private func dayCellButton(date: Date) -> some View {
        Button {
            viewModel.selectedDate = date
        } label: {
            DayCell(
                date: date,
                meals: mealsForDate(date),
                isToday: viewModel.isToday(date)
            )
        }
        .buttonStyle(.plain)
    }

}

// MARK: - DayCell

/// 캘린더 그리드의 개별 날짜 셀
private struct DayCell: View {

    let date: Date
    let meals: [Meal]
    let isToday: Bool

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    private var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    /// 표시할 식사 (최대 3개)
    private var displayedMeals: [Meal] { Array(meals.prefix(3)) }
    /// 초과 개수
    private var overflowCount: Int { max(0, meals.count - 3) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 배경
            RoundedRectangle(cornerRadius: 10)
                .fill(isToday ? Color.orange.opacity(0.08) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isToday ? Color.orange : Color.clear, lineWidth: 1.5)
                )

            VStack(spacing: 0) {
                // 날짜 숫자
                HStack {
                    Text("\(dayNumber)")
                        .font(.system(size: 12, weight: isToday ? .bold : .regular))
                        .foregroundStyle(
                            isToday ? .orange :
                            isWeekend ? (Calendar.current.component(.weekday, from: date) == 1 ? .red : .blue) :
                            .primary
                        )
                        .frame(minWidth: 20, minHeight: 20)
                        .background(
                            Circle()
                                .fill(isToday ? Color.orange : .clear)
                                .frame(width: 22, height: 22)
                                .opacity(isToday ? 0.15 : 0)
                        )
                    Spacer()
                }
                .padding(.leading, 6)
                .padding(.top, 5)

                // 스티커 더미
                if !displayedMeals.isEmpty {
                    stickerPile
                }

                Spacer(minLength: 0)
            }

            // 오버플로우 뱃지
            if overflowCount > 0 {
                Text("+\(overflowCount)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .clipShape(Capsule())
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .frame(height: 90)
    }

    // MARK: - Sticker Pile

    /// 최대 3개의 스티커를 살짝 겹쳐 쌓는 연출
    @ViewBuilder
    private var stickerPile: some View {
        let stickerSize: CGFloat = 44
        // 인덱스별 고정 오프셋 & 회전 (결정적, 랜덤 아님)
        let offsets: [(CGFloat, CGFloat)] = [(0, 0), (-6, 3), (5, -4)]
        let rotations: [Double] = [-5, 8, -3]

        ZStack {
            ForEach(Array(displayedMeals.enumerated()), id: \.element.id) { index, meal in
                MealStickerView(
                    meal: meal,
                    size: stickerSize,
                    rotation: rotations[index % rotations.count]
                )
                .offset(
                    x: offsets[index % offsets.count].0,
                    y: offsets[index % offsets.count].1
                )
                .zIndex(Double(index))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
    .modelContainer(for: Meal.self, inMemory: true)
}
