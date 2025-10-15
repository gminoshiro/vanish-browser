//
//  DownloadProgressView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI

struct DownloadProgressView: View {
    let fileName: String
    let progress: Double

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // より大きなアイコン
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("ダウンロード中")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(fileName)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    Text("\(Int(progress * 100))% 完了")
                        .font(.callout)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }

                Spacer()
            }

            // より目立つプログレスバー
            VStack(spacing: 4) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .scaleEffect(y: 2.0)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        )
        .padding(.horizontal, 20)
    }
}
