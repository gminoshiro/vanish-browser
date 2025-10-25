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

class TabManager: ObservableObject {
    @Published var tabs: [Tab] = []
    @Published var currentTabId: UUID?

    init() {
        // 初期タブを作成
        let initialTab = Tab()
        tabs = [initialTab]
        currentTabId = initialTab.id

        // 履歴削除通知を受け取る
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearAllTabsData),
            name: NSNotification.Name("ClearAllTabsData"),
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
    }
}
