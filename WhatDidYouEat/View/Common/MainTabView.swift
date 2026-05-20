//
//  MainTabView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI
import SwiftData

/// 앱의 최상위 탭 네비게이션
struct MainTabView: View {

    var body: some View {
        TabView {
            // Tab 1: 캘린더 (메인)
            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("캘린더", systemImage: "calendar")
            }

            // Tab 2: 기록하기
            NavigationStack {
                CameraView()
            }
            .tabItem {
                Label("기록하기", systemImage: "camera.fill")
            }

            // Tab 3: 통계
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("통계", systemImage: "chart.bar.fill")
            }
        }
        .tint(.orange)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Meal.self, inMemory: true)
}
