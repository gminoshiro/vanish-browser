//
//  BrowsingHistory.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/12.
//

import Foundation
import Combine

struct BrowsingHistoryItem: Identifiable, Codable {
    let id: UUID
    let url: String
    let title: String
    let visitedAt: Date

    init(id: UUID = UUID(), url: String, title: String, visitedAt: Date = Date()) {
        self.id = id
        self.url = url
        self.title = title
        self.visitedAt = visitedAt
    }
}

class BrowsingHistoryManager: ObservableObject {
    static let shared = BrowsingHistoryManager()

    @Published private(set) var history: [BrowsingHistoryItem] = []

    private let historyKey = "browsingHistory"
    private let maxHistoryItems = 1000

    private init() {
        loadHistory()
    }

    func addToHistory(url: String, title: String) {
        // 同じURLがある場合は削除してから追加（最新を上に）
        history.removeAll { $0.url == url }

        let item = BrowsingHistoryItem(url: url, title: title)
        history.insert(item, at: 0)

        // 最大件数を超えたら古いものを削除
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }

        saveHistory()
    }

    func clearHistory() {
        print("🗑️ BrowsingHistoryManager: 履歴を削除します（現在: \(history.count)件）")
        history.removeAll()
        saveHistory()
        print("🗑️ BrowsingHistoryManager: 履歴削除完了（残り: \(history.count)件）")
    }

    func deleteHistoryItem(_ item: BrowsingHistoryItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    func searchHistory(query: String) -> [BrowsingHistoryItem] {
        if query.isEmpty {
            return history
        }
        return history.filter { item in
            item.url.localizedCaseInsensitiveContains(query) ||
            item.title.localizedCaseInsensitiveContains(query)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([BrowsingHistoryItem].self, from: data) else {
            return
        }
        history = decoded
    }

    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(history) else {
            return
        }
        UserDefaults.standard.set(encoded, forKey: historyKey)
    }
}
