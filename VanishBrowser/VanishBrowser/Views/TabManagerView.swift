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
    @State private var selectedMode: TabMode = .normal

    enum TabMode: String, CaseIterable {
        case normal = "通常"
        case private_ = "プライベート"
    }

    var filteredTabs: [Tab] {
        tabManager.activeTabs.filter { tab in
            if selectedMode == .normal {
                return !tab.isPrivate
            } else {
                return tab.isPrivate
            }
        }
    }

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

                    // モード切り替えセグメント
                    Picker("", selection: $selectedMode) {
                        Text("通常").tag(TabMode.normal)
                        Text("プライベート").tag(TabMode.private_)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)

                    Spacer()

                    Button(action: {
                        // 現在のモードに応じて新規タブを作成
                        tabManager.createNewTab(isPrivate: selectedMode == .private_)
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
                        ForEach(filteredTabs) { tab in
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
                        // 現在のモードのタブを全て閉じる
                        let tabsToClose = filteredTabs.map { $0.id }
                        tabsToClose.forEach { tabManager.closeTab($0) }
                    }) {
                        Text("全てを閉じる")
                            .foregroundColor(.red)
                    }
                    .disabled(filteredTabs.isEmpty)

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
        ZStack(alignment: .topTrailing) {
            // メインカード
            VStack(spacing: 0) {
                // カードヘッダー
                HStack {
                    // ファビコン
                    if tab.isPrivate {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.purple.opacity(0.7)))
                    } else {
                        Text(String(tab.title.prefix(1)).uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.blue.opacity(0.7)))
                    }

                    Text(tab.title.isEmpty ? "新規タブ" : tab.title)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    // ×ボタンのスペース確保
                    Color.clear
                        .frame(width: 28, height: 28)
                }
                .padding()
                .background(tab.isPrivate ? Color.purple.opacity(0.05) : Color(.secondarySystemBackground))

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
            .onTapGesture {
                print("🔵 カードタップ: タブID=\(tab.id), タイトル=\(tab.title)")
                onTap()
            }

            // ×ボタン（最上位レイヤー）
            Button(action: {
                print("🔴 ×ボタンタップ: タブID=\(tab.id), タイトル=\(tab.title)")
                onClose()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 28, height: 28)

                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
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
