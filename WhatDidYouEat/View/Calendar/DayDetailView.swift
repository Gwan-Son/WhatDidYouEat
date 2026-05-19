//
//  DayDetailView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI
import SwiftData

/// 특정 날짜의 식사 기록 상세 뷰
struct DayDetailView: View {

    @Environment(\.modelContext) private var modelContext

    let date: Date

    /// @Query로 자동 갱신 — 해당 날짜 식사만 필터
    @Query private var meals: [Meal]

    @State private var mealToDelete: Meal? = nil
    @State private var showDeleteConfirm = false

    init(date: Date) {
        self.date = date
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        _meals = Query(
            filter: #Predicate<Meal> { $0.date >= start && $0.date < end },
            sort: \.createdAt
        )
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
    }

    var body: some View {
        Group {
            if meals.isEmpty {
                emptyState
            } else {
                mealList
            }
        }
        .navigationTitle(dateTitle)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "이 기록을 삭제할까요?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                if let meal = mealToDelete {
                    modelContext.delete(meal)
                    try? modelContext.save()
                }
            }
            Button("취소", role: .cancel) {}
        }
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var mealList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(meals) { meal in
                    MealCardView(
                        meal: meal,
                        onDelete: {
                            mealToDelete = meal
                            showDeleteConfirm = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 52))
                .foregroundStyle(Color(.systemGray3))

            Text("이 날은 기록이 없어요")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - MealCardView

/// 하나의 식사 기록을 표시하는 카드
private struct MealCardView: View {

    let meal: Meal
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 누끼 이미지
            MealStickerDetailView(meal: meal)
                .padding([.horizontal, .top], 16)

            // 음식 이름 + 메모
            VStack(alignment: .leading, spacing: 6) {
                if let name = meal.name, !name.isEmpty {
                    Text(name)
                        .font(.headline)
                }

                if let memo = meal.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // 기록 시각
                Text(meal.createdAt, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 16)

            // 액션 버튼
            HStack {
                // 공유
                if let shareImage = UIImage(data: meal.maskedImageData) {
                    ShareLink(
                        item: Image(uiImage: shareImage),
                        preview: SharePreview(
                            meal.name ?? "음식 누끼",
                            image: Image(uiImage: shareImage)
                        )
                    ) {
                        Label("공유", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                // 삭제
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("삭제", systemImage: "trash")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}
