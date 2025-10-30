//
//  TabManager.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/10.
//

import Foundation
import Combine
import SwiftUI
import UIKit
import WebKit

// タブの永続化用構造体
private struct PersistedTab: Codable {
    let id: String
    let url: String
    let title: String
    let isPrivate: Bool
    let createdAt: Date
}

class TabManager: ObservableObject {
    @Published var tabs: [Tab] = []
    @Published var currentTabId: UUID?

    init() {
        // 保存されたタブを復元
        loadTabs()

        // 履歴削除通知を受け取る
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearAllTabsData),
            name: NSNotification.Name("ClearAllTabsData"),
            object: nil
        )

        // タブ削除通知を受け取る
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deleteOldTabs(_:)),
            name: NSNotification.Name("DeleteOldTabs"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func clearAllTabsData() {
        print("🧹 TabManager: すべてのタブの履歴を削除します")
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()

        // すべてのタブのWebViewのdataStoreを削除
        for tab in tabs {
            let dataStore = tab.webView.configuration.websiteDataStore
            dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
                dataStore.removeData(ofTypes: dataTypes, for: records) {
                    print("🧹 タブ[\(tab.title)]のデータ削除完了")
                }
            }
        }
    }

    var currentTab: Tab? {
        return tabs.first { $0.id == currentTabId }
    }

    var activeTabs: [Tab] {
        tabs
    }

    func createNewTab(url: String = "", isPrivate: Bool = false) {
        let newTab = Tab(url: url, isPrivate: isPrivate)
        tabs.append(newTab)
        currentTabId = newTab.id
        saveTabs()
    }

    func closeTab(_ tabId: UUID) {
        print("🗑️ TabManager.closeTab 呼び出し: タブID=\(tabId)")

        if let index = tabs.firstIndex(where: { $0.id == tabId }) {
            let wasPrivate = tabs[index].isPrivate
            print("  - タブ見つかった: index=\(index), isPrivate=\(wasPrivate), title=\(tabs[index].title)")

            // 通常タブの場合、通常タブが1個しかないなら削除せず新規タブ作成
            // プライベートタブの場合、全タブが1個なら新規タブ作成
            let normalTabs = tabs.filter { !$0.isPrivate }
            let isLastNormalTab = !wasPrivate && normalTabs.count == 1
            let isLastTab = tabs.count == 1

            print("  - 総タブ数: \(tabs.count)")
            print("  - 通常タブ数: \(normalTabs.count)")
            print("  - isLastNormalTab: \(isLastNormalTab)")
            print("  - isLastTab: \(isLastTab)")

            tabs.remove(at: index)
            print("  - タブ削除完了、残りタブ数: \(tabs.count)")

            // 通常タブの最後の1個、または全体の最後の1個を閉じた場合
            if isLastNormalTab || isLastTab {
                let newTab = Tab(isPrivate: wasPrivate)
                tabs.append(newTab)
                currentTabId = newTab.id
                print("  ✅ 新規タブ作成: isPrivate=\(wasPrivate)")
            } else if currentTabId == tabId {
                // 現在のタブを閉じた場合は、前のタブに切り替え
                if index > 0 {
                    currentTabId = tabs[index - 1].id
                } else {
                    currentTabId = tabs.first?.id
                }
                print("  ✅ タブ切り替え完了")
            } else {
                print("  ✅ タブ削除のみ完了（現在のタブではない）")
            }

            saveTabs()
        } else {
            print("  ❌ タブが見つかりません")
        }
    }

    func switchTab(to tabId: UUID) {
        currentTabId = tabId
    }

    func updateTab(_ tabId: UUID, title: String? = nil, url: String? = nil, snapshot: UIImage? = nil) {
        if let index = tabs.firstIndex(where: { $0.id == tabId }) {
            if let title = title {
                tabs[index].title = title
            }
            if let url = url {
                tabs[index].url = url
            }
            if let snapshot = snapshot {
                tabs[index].snapshot = snapshot
            }
            saveTabs()
        }
    }

    func moveTabs(from source: IndexSet, to destination: Int, isPrivate: Bool) {
        // フィルタリングされたタブ（通常またはプライベート）のみを対象に並び替え
        var filteredTabs = tabs.filter { $0.isPrivate == isPrivate }
        filteredTabs.move(fromOffsets: source, toOffset: destination)

        // 元のtabs配列を再構築
        var newTabs: [Tab] = []
        var filteredIndex = 0

        for tab in tabs {
            if tab.isPrivate == isPrivate {
                newTabs.append(filteredTabs[filteredIndex])
                filteredIndex += 1
            } else {
                newTabs.append(tab)
            }
        }

        tabs = newTabs
        saveTabs()
    }

    @objc private func deleteOldTabs(_ notification: Notification) {
        guard let cutoffDate = notification.userInfo?["cutoffDate"] as? Date else {
            print("❌ タブ削除: cutoffDateが取得できません")
            return
        }

        print("🗑️ TabManager: \(cutoffDate)以前のタブを削除")

        let initialCount = tabs.count
        tabs.removeAll { tab in
            tab.createdAt < cutoffDate
        }

        let deletedCount = initialCount - tabs.count
        print("🗑️ 削除完了: \(deletedCount)個のタブを削除")

        // 最低1つのタブは残す
        if tabs.isEmpty {
            print("⚠️ すべてのタブが削除されたため、新規タブを作成")
            let newTab = Tab()
            tabs.append(newTab)
            currentTabId = newTab.id
        }

        saveTabs()
    }

    // MARK: - タブの永続化

    /// タブをUserDefaultsに保存
    func saveTabs() {
        let persistedTabs = tabs.map { tab in
            PersistedTab(
                id: tab.id.uuidString,
                url: tab.url,
                title: tab.title,
                isPrivate: tab.isPrivate,
                createdAt: tab.createdAt
            )
        }

        if let encoded = try? JSONEncoder().encode(persistedTabs) {
            UserDefaults.standard.set(encoded, forKey: "savedTabs")
            print("💾 タブ保存完了: \(persistedTabs.count)個")
        }
    }

    /// UserDefaultsからタブを復元
    private func loadTabs() {
        guard let data = UserDefaults.standard.data(forKey: "savedTabs"),
              let persistedTabs = try? JSONDecoder().decode([PersistedTab].self, from: data),
              !persistedTabs.isEmpty else {
            // 保存されたタブがない場合は新規タブ作成
            print("📱 保存されたタブなし: 新規タブ作成")
            let initialTab = Tab()
            tabs = [initialTab]
            currentTabId = initialTab.id
            return
        }

        // タブを復元
        tabs = persistedTabs.map { persisted in
            Tab(
                id: UUID(uuidString: persisted.id) ?? UUID(),
                title: persisted.title,
                url: persisted.url,
                snapshot: nil,
                isPrivate: persisted.isPrivate,
                createdAt: persisted.createdAt
            )
        }

        currentTabId = tabs.first?.id
        print("📱 タブ復元完了: \(tabs.count)個")
    }
}
