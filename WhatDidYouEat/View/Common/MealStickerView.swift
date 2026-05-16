//
//  MealStickerView.swift
//  WhatDidYouEat
//
//  Created by 심관혁 on 5/12/26.
//

import SwiftUI

/// 누끼 처리된 음식 이미지를 스티커 형태로 렌더링하는 공통 컴포넌트
struct MealStickerView: View {

    let meal: Meal
    /// 표시할 크기
    var size: CGFloat = 60
    /// 회전 각도 (스티커 효과)
    var rotation: Double = 0
    /// 그림자 표시 여부
    var showShadow: Bool = true

    var body: some View {
        Group {
            if let image = maskedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                // 이미지 로드 실패 시 폴백
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .rotationEffect(.degrees(rotation))
        .shadow(
            color: showShadow ? .black.opacity(0.18) : .clear,
            radius: 4,
            x: 1,
            y: 2
        )
    }

    private var maskedImage: UIImage? {
        UIImage(data: meal.maskedImageData)
    }
}

// MARK: - Large Detail Variant

/// 상세 화면에서 사용하는 큰 스티커 뷰
struct MealStickerDetailView: View {

    let meal: Meal

    var body: some View {
        ZStack {
            // 체커보드 (투명 배경 시각화)
            CheckerboardBackground()
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if let image = UIImage(data: meal.maskedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Checkerboard Background

/// 투명 배경 시각화용 체커보드 (MaskPreviewView에서도 재사용)
struct CheckerboardBackground: View {
    var tileSize: CGFloat = 12

    var body: some View {
        Canvas { context, size in
            let cols = Int(ceil(size.width  / tileSize))
            let rows = Int(ceil(size.height / tileSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let color: Color = isLight ? Color(.systemGray5) : Color(.systemGray6)
                    let rect = CGRect(
                        x: CGFloat(col) * tileSize,
                        y: CGFloat(row) * tileSize,
                        width: tileSize,
                        height: tileSize
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}
