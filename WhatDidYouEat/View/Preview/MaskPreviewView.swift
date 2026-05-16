//
//  MaskPreviewView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI
import SwiftData

/// 누끼 처리 결과 확인 + 음식 이름/메모 입력 + 저장
struct MaskPreviewView: View {

    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CameraViewModel

    @FocusState private var focusedField: Field?

    private enum Field { case name, memo }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: 누끼 이미지 미리보기
                    maskedImageSection

                    // MARK: 날짜 선택
                    dateSection

                    // MARK: 음식 이름 / 메모 입력
                    inputSection

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("음식 확인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay(alignment: .bottom) { saveButtonOverlay }
            // 저장 완료 시 자동 닫기
            .onChange(of: viewModel.cameraState) { _, newState in
                if newState == .saved {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Sections

    /// 투명 배경(체커보드) 위에 누끼 이미지 표시
    @ViewBuilder
    private var maskedImageSection: some View {
        ZStack {
            // 체커보드: 투명 영역 시각화
            CheckerboardBackground()
                .clipShape(RoundedRectangle(cornerRadius: 20))

            if let maskedImage = viewModel.maskResult?.maskedImage {
                Image(uiImage: maskedImage)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("먹은 날짜", systemImage: "calendar")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            DatePicker(
                "",
                selection: $viewModel.mealDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var inputSection: some View {
        VStack(spacing: 12) {
            // 음식 이름
            VStack(alignment: .leading, spacing: 8) {
                Label("음식 이름", systemImage: "fork.knife")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                TextField("예: 된장찌개, 파스타 (선택)", text: $viewModel.mealName)
                    .font(.body)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .memo }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // 메모
            VStack(alignment: .leading, spacing: 8) {
                Label("메모", systemImage: "note.text")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                TextField("맛있었나요? (선택)", text: $viewModel.memo, axis: .vertical)
                    .font(.body)
                    .lineLimit(3, reservesSpace: true)
                    .focused($focusedField, equals: .memo)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    /// 하단 고정 저장 버튼
    @ViewBuilder
    private var saveButtonOverlay: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                // 다시 찍기
                Button {
                    dismiss()
                } label: {
                    Text("다시 찍기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // 저장하기
                Button {
                    focusedField = nil
                    Task { await viewModel.saveMeal() }
                } label: {
                    Group {
                        if viewModel.cameraState == .saving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("저장하기")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.cameraState == .saving)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("취소") { dismiss() }
        }
    }
}

#Preview {
    // Preview용 더미 ViewModel (실제 Vision 처리 없이 UI 확인)
    MaskPreviewView(
        viewModel: {
            // 실제 앱에서는 VisionMaskService 결과를 받아 state가 설정됨
            let vm = CameraViewModel(
                repository: LocalMealRepository(
                    modelContext: try! ModelContainer(for: Meal.self, configurations: .init(isStoredInMemoryOnly: true)).mainContext
                )
            )
            return vm
        }()
    )
}
