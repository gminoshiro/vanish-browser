//
//  TabBarView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/10.
//

import SwiftUI

struct TabBarView: View {
    @ObservedObject var tabManager: TabManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabManager.tabs) { tab in
                    TabItemView(
                        tab: tab,
                        isSelected: tabManager.currentTabId == tab.id,
                        onTap: {
                            tabManager.switchTab(to: tab.id)
                        },
                        onClose: {
                            tabManager.closeTab(tab.id)
                        }
                    )
                }

                // 新規タブボタン
                Button(action: {
                    tabManager.createNewTab()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .padding(.leading, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
}

struct TabItemView: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            // ファビコン（簡易版：最初の文字）
            Text(String(tab.title.prefix(1)).uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.7))
                )

            // タイトル（省略表示）
            Text(tab.title.isEmpty ? "新規" : tab.title)
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: 60)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(width: 14, height: 14)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
        )
        .onTapGesture {
            onTap()
        }
    }
}
