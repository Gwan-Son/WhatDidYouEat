//
//  DayDetailView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI
import SwiftData
import AVFoundation

/// 특정 날짜의 식사 기록 상세 뷰
struct DayDetailView: View {

    @Environment(\.modelContext) private var modelContext

    let date: Date

    /// @Query로 자동 갱신 — 해당 날짜 식사만 필터
    @Query private var meals: [Meal]

    @State private var mealToDelete: Meal? = nil
    @State private var mealToEdit: Meal? = nil
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
        .sheet(item: $mealToEdit) { meal in
            EditMealView(meal: meal)
        }
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
                        onEdit: {
                            mealToEdit = meal
                        },
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
    let onEdit: () -> Void
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

                Button {
                    onEdit()
                } label: {
                    Label("수정", systemImage: "pencil")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }

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

// MARK: - EditMealView

private struct EditMealView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let meal: Meal

    @State private var mealName: String
    @State private var memo: String
    @State private var mealDate: Date
    @State private var originalImageData: Data?
    @State private var maskedImageData: Data
    @State private var isProcessingImage = false
    @State private var imageErrorMessage: String?
    @State private var showingPhotoSourceDialog = false
    @State private var showingImagePicker = false
    @State private var showingCameraPicker = false
    @FocusState private var focusedField: Field?

    private let maskService = VisionMaskService()

    private enum Field { case name, memo }

    init(meal: Meal) {
        self.meal = meal
        _mealName = State(initialValue: meal.name ?? "")
        _memo = State(initialValue: meal.memo ?? "")
        _mealDate = State(initialValue: meal.date)
        _originalImageData = State(initialValue: meal.originalImageData)
        _maskedImageData = State(initialValue: meal.maskedImageData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    editImagePreview

                    Button {
                        showingPhotoSourceDialog = true
                    } label: {
                        Label("사진 변경", systemImage: "photo.badge.plus")
                    }
                    .disabled(isProcessingImage)
                } header: {
                    Text("사진")
                } footer: {
                    if let imageErrorMessage {
                        Text(imageErrorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    DatePicker(
                        "먹은 날짜",
                        selection: $mealDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .tint(.orange)
                }

                Section("기록") {
                    TextField("음식 이름", text: $mealName)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .memo }

                    TextField("메모", text: $memo, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .focused($focusedField, equals: .memo)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                }
            }
            .navigationTitle("기록 수정")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "사진 변경",
                isPresented: $showingPhotoSourceDialog,
                titleVisibility: .visible
            ) {
                Button("카메라로 촬영") {
                    Task { await openCameraIfAvailable() }
                }

                Button("갤러리에서 선택") {
                    showingImagePicker = true
                }

                Button("취소", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView { image in
                    showingImagePicker = false
                    Task { await replaceImage(with: image) }
                } onCancel: {
                    showingImagePicker = false
                } onLoadFailed: {
                    showingImagePicker = false
                    imageErrorMessage = MaskError.photoLibraryLoadFailed.localizedDescription
                }
            }
            .sheet(isPresented: $showingCameraPicker) {
                CameraPickerView { image in
                    showingCameraPicker = false
                    Task { await replaceImage(with: image) }
                } onCancel: {
                    showingCameraPicker = false
                } onCaptureFailed: {
                    showingCameraPicker = false
                    imageErrorMessage = MaskError.captureFailed.localizedDescription
                }
                .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { saveChanges() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private var editImagePreview: some View {
        ZStack {
            CheckerboardBackground()
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let image = UIImage(data: maskedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }

            if isProcessingImage {
                Color.black.opacity(0.18)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                ProgressView()
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        }
    }

    private func saveChanges() {
        let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)

        meal.date = mealDate
        meal.originalImageData = originalImageData
        meal.maskedImageData = maskedImageData
        meal.name = trimmedName.isEmpty ? nil : trimmedName
        meal.memo = trimmedMemo.isEmpty ? nil : trimmedMemo

        try? modelContext.save()
        dismiss()
    }

    private func replaceImage(with image: UIImage) async {
        isProcessingImage = true
        imageErrorMessage = nil

        do {
            let result = try await maskService.removeBackground(from: image)
            originalImageData = result.originalImage.jpegData(compressionQuality: 0.8)
            maskedImageData = result.maskedImageData
        } catch let error as MaskError {
            imageErrorMessage = error.localizedDescription
        } catch {
            imageErrorMessage = MaskError.renderFailed.localizedDescription
        }

        isProcessingImage = false
    }

    private func openCameraIfAvailable() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showingImagePicker = true
            imageErrorMessage = MaskError.cameraUnavailable.localizedDescription
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCameraPicker = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                showingCameraPicker = true
            } else {
                imageErrorMessage = MaskError.cameraPermissionDenied.localizedDescription
            }
        case .denied, .restricted:
            imageErrorMessage = MaskError.cameraPermissionDenied.localizedDescription
        @unknown default:
            imageErrorMessage = MaskError.cameraPermissionDenied.localizedDescription
        }
    }
}
