//
//  LocalMealRepository.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import Foundation
import SwiftData

/// SwiftData 기반 로컬 MealRepository 구현체 (Phase 1)
@MainActor
final class LocalMealRepository: MealRepository {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    func fetchMeals(for date: Date) async -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        let predicate = #Predicate<Meal> { meal in
            meal.date >= startOfDay && meal.date < endOfDay
        }
        let descriptor = FetchDescriptor<Meal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchMeals(year: Int, month: Int) async -> [Meal] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        let calendar = Calendar.current
        guard
            let startOfMonth = calendar.date(from: components),
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
        else { return [] }

        let predicate = #Predicate<Meal> { meal in
            meal.date >= startOfMonth && meal.date < endOfMonth
        }
        let descriptor = FetchDescriptor<Meal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Write

    func save(_ meal: Meal) async throws {
        modelContext.insert(meal)
        try modelContext.save()
    }

    func delete(_ meal: Meal) async throws {
        modelContext.delete(meal)
        try modelContext.save()
    }
}
