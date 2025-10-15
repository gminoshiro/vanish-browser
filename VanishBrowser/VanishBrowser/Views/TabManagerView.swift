//
//  TabManagerView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/10.
//

import SwiftUI

struct TabManagerView: View {
    @ObservedObject var tabManager: TabManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("完了")
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    Text("タブ")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        tabManager.createNewTab()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }
                .padding()

                // タブカード一覧
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(tabManager.activeTabs) { tab in
                            TabCardView(
                                tab: tab,
                                isSelected: tabManager.currentTabId == tab.id,
                                onTap: {
                                    tabManager.switchTab(to: tab.id)
                                    dismiss()
                                },
                                onClose: {
                                    tabManager.closeTab(tab.id)
                                }
                            )
                        }
                    }
                    .padding()
                }

                Spacer()

                // 下部ボタン
                HStack {
                    Spacer()

                    Button(action: {
                        // 全て閉じる
                        let allTabIds = tabManager.activeTabs.map { $0.id }
                        if allTabIds.count > 1 {
                            allTabIds.dropLast().forEach { tabManager.closeTab($0) }
                        }
                    }) {
                        Text("全てを閉じる")
                            .foregroundColor(.red)
                    }

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct TabCardView: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void
    let onClose: () -> Void
    @State private var showShareSheet = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // カードヘッダー
                HStack {
                    // ファビコン
                    Text(String(tab.title.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.blue.opacity(0.7)))

                    Text(tab.title.isEmpty ? "新規タブ" : tab.title)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))

                // カードコンテンツ（スクリーンショット）
                ZStack {
                    Color(.systemGray6)

                    if let snapshot = tab.snapshot {
                        // スナップショット画像を表示
                        Image(uiImage: snapshot)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    } else {
                        // スナップショットがない場合はプレースホルダー
                        VStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)

                            Text(tab.url.isEmpty ? "新規タブ" : tab.url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                .frame(height: 200)
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = tab.url
            }) {
                Label("URLをコピー", systemImage: "doc.on.doc")
            }

            Button(action: {
                NotificationCenter.default.post(
                    name: NSNotification.Name("DuplicateTab"),
                    object: nil,
                    userInfo: ["url": tab.url]
                )
            }) {
                Label("タブを複製", systemImage: "plus.square.on.square")
            }

            Button(action: {
                showShareSheet = true
            }) {
                Label("共有", systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive, action: onClose) {
                Label("閉じる", systemImage: "xmark")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if !tab.url.isEmpty, let url = URL(string: tab.url) {
                ShareSheet(items: [url])
            }
        }
    }
}
