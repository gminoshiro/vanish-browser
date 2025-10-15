//
//  BrowsingHistoryView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/12.
//

import SwiftUI

struct BrowsingHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var historyManager = BrowsingHistoryManager.shared
    @State private var searchQuery = ""
    @State private var showClearAlert = false

    var onSelectURL: (String) -> Void

    var filteredHistory: [BrowsingHistoryItem] {
        historyManager.searchHistory(query: searchQuery)
    }

    var body: some View {
        NavigationView {
            Group {
                if filteredHistory.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(searchQuery.isEmpty ? "閲覧履歴はありません" : "検索結果がありません")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(groupedHistory, id: \.key) { section in
                            Section(header: Text(section.key)) {
                                ForEach(section.value) { item in
                                    Button(action: {
                                        onSelectURL(item.url)
                                        dismiss()
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title.isEmpty ? item.url : item.title)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)

                                            Text(item.url)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)

                                            Text(formatTime(item.visitedAt))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            historyManager.deleteHistoryItem(item)
                                        } label: {
                                            Label("削除", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("閲覧履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {
                            showClearAlert = true
                        }) {
                            Label("全ての履歴を削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(filteredHistory.isEmpty)
                }
            }
            .searchable(text: $searchQuery, prompt: "履歴を検索")
            .alert("履歴を全て削除", isPresented: $showClearAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    historyManager.clearHistory()
                }
            } message: {
                Text("全ての閲覧履歴が削除されます。この操作は取り消せません。")
            }
        }
    }

    // 日付でグループ化
    var groupedHistory: [(key: String, value: [BrowsingHistoryItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredHistory) { item -> String in
            if calendar.isDateInToday(item.visitedAt) {
                return "今日"
            } else if calendar.isDateInYesterday(item.visitedAt) {
                return "昨日"
            } else if calendar.isDate(item.visitedAt, equalTo: Date(), toGranularity: .weekOfYear) {
                return "今週"
            } else if calendar.isDate(item.visitedAt, equalTo: Date(), toGranularity: .month) {
                return "今月"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy年M月"
                return formatter.string(from: item.visitedAt)
            }
        }

        // ソート順序を定義
        let order = ["今日", "昨日", "今週", "今月"]
        return grouped.sorted { item1, item2 in
            if let index1 = order.firstIndex(of: item1.key),
               let index2 = order.firstIndex(of: item2.key) {
                return index1 < index2
            } else if order.contains(item1.key) {
                return true
            } else if order.contains(item2.key) {
                return false
            } else {
                return item1.key > item2.key
            }
        }
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
