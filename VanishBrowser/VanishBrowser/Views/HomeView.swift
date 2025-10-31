//
//  HomeView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/25.
//

import SwiftUI

struct HomeView: View {
    let onSearch: (String) -> Void
    let onBookmarkTap: (String) -> Void
    @State private var searchText = ""

    // よく使うブックマーク（後で動的に取得可能）
    let quickBookmarks: [QuickBookmark] = [
        QuickBookmark(title: "Search", icon: "magnifyingglass", url: "https://www.google.com", color: .primary),
        QuickBookmark(title: "YouTube", icon: "play.rectangle.fill", url: "https://youtube.com", color: .primary),
        QuickBookmark(title: "Maps", icon: "map.fill", url: "https://maps.google.com", color: .primary),
        QuickBookmark(title: "Weather", icon: "cloud.sun.fill", url: "https://weather.yahoo.co.jp/", color: .primary),
        QuickBookmark(title: "News", icon: "newspaper.fill", url: "https://news.yahoo.co.jp/", color: .primary),
    ]

    var body: some View {
        ZStack {
            // ダークグレー背景（アプリアイコンに合わせる）
            Color(red: 0.11, green: 0.11, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Vanishロゴ - シンプルに白のみ
                Text("Vanish")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 80)

                // 検索バー - シンプル
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 16))

                    TextField("検索またはURLを入力", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .accentColor(.white)
                        .onSubmit {
                            if !searchText.isEmpty {
                                onSearch(searchText)
                            }
                        }

                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 30)

                // クイックアクセスブックマーク
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(quickBookmarks) { bookmark in
                        QuickBookmarkButton(bookmark: bookmark) {
                            onBookmarkTap(bookmark.url)
                        }
                    }
                }
                .padding(.horizontal, 30)

                Spacer()
                Spacer()
            }
        }
    }
}

struct QuickBookmark: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let url: String
    let color: Color
}

struct QuickBookmarkButton: View {
    let bookmark: QuickBookmark
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 60, height: 60)

                Image(systemName: bookmark.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.7))
            }

            Text(bookmark.title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

// プレビュー用
#Preview {
    HomeView(
        onSearch: { _ in },
        onBookmarkTap: { _ in }
    )
}
