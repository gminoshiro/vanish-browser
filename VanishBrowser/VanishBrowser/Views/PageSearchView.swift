//
//  PageSearchView.swift
//  VanishBrowser
//
//  Created by Claude on 2025/10/12.
//

import SwiftUI

struct PageSearchView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let currentMatch: Int
    let totalMatches: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // 検索フィールド
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("ページ内を検索", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // マッチ数表示
            if totalMatches > 0 {
                Text("\(currentMatch)/\(totalMatches)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 40)
            } else if !searchText.isEmpty {
                Text("0件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 40)
            }

            // 前へボタン
            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
            }
            .disabled(totalMatches == 0)

            // 次へボタン
            Button(action: onNext) {
                Image(systemName: "chevron.down")
            }
            .disabled(totalMatches == 0)

            // 完了ボタン
            Button(action: onDone) {
                Text("完了")
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}
