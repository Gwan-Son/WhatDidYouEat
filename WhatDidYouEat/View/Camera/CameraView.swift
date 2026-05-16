//
//  CameraView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI
import SwiftData

/// 음식 기록 진입점 — 카메라 / 갤러리 선택 + Vision 처리 상태 표시
struct CameraView: View {

    @Environment(\.modelContext) private var modelContext

    /// onAppear에서 modelContext를 받아 초기화
    @State private var viewModel: CameraViewModel?

    var body: some View {
        ZStack {
            // 배경
            Color(.systemBackground).ignoresSafeArea()

            if let vm = viewModel {
                switch vm.cameraState {
                case .idle:
                    idleView(vm: vm)

                case .processing:
                    processingView()

                case .error(let error):
                    errorView(error: error, vm: vm)

                case .preview, .saving, .saved:
                    // MaskPreviewView로 fullScreenCover 전환
                    idleView(vm: vm)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("기록하기")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { setupViewModelIfNeeded() }
        // 갤러리 피커
        .sheet(isPresented: Binding(
            get: { viewModel?.showingImagePicker ?? false },
            set: { viewModel?.showingImagePicker = $0 }
        )) {
            ImagePickerView { image in
                viewModel?.showingImagePicker = false
                Task { await viewModel?.processImage(image) }
            }
        }
        // 카메라 피커
        .fullScreenCover(isPresented: Binding(
            get: { viewModel?.showingCameraPicker ?? false },
            set: { viewModel?.showingCameraPicker = $0 }
        )) {
            CameraPickerView { image in
                viewModel?.showingCameraPicker = false
                Task { await viewModel?.processImage(image) }
            }
            .ignoresSafeArea()
        }
        // 누끼 결과 화면
        .fullScreenCover(isPresented: Binding(
            get: { viewModel?.isShowingPreview ?? false },
            set: { if !$0 { viewModel?.reset() } }
        )) {
            if let vm = viewModel {
                MaskPreviewView(viewModel: vm)
            }
        }
    }

    // MARK: - Sub Views

    /// 대기 상태: 카메라 / 갤러리 선택 버튼
    @ViewBuilder
    private func idleView(vm: CameraViewModel) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // 상단 안내
            VStack(spacing: 12) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, options: .nonRepeating)

                Text("오늘 뭐 먹었어?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("음식 사진을 찍으면\n자동으로 누끼를 따드려요 ✂️")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            // 버튼 영역
            VStack(spacing: 14) {
                // 카메라 버튼 (primary)
                Button {
                    vm.showingCameraPicker = true
                } label: {
                    Label("카메라로 촬영", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // 갤러리 버튼 (secondary)
                Button {
                    vm.showingImagePicker = true
                } label: {
                    Label("갤러리에서 선택", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.orange.opacity(0.12))
                        .foregroundStyle(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    /// Vision 처리 중 상태
    @ViewBuilder
    private func processingView() -> some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.8)
                .tint(.orange)

            VStack(spacing: 6) {
                Text("음식 인식 중...")
                    .font(.headline)
                Text("배경을 제거하고 있어요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// 에러 상태
    @ViewBuilder
    private func errorView(error: MaskError, vm: CameraViewModel) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text(error.errorDescription ?? "오류가 발생했습니다")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button("다시 시도") {
                vm.reset()
            }
            .font(.headline)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(.orange)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Setup

    private func setupViewModelIfNeeded() {
        guard viewModel == nil else { return }
        viewModel = CameraViewModel(
            repository: LocalMealRepository(modelContext: modelContext)
        )
    }
}

#Preview {
    NavigationStack {
        CameraView()
    }
    .modelContainer(for: Meal.self, inMemory: true)
}
