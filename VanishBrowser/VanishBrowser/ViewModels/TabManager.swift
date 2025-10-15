//
//  TabManager.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/10.
//

import Foundation
import Combine
import UIKit

class TabManager: ObservableObject {
    @Published var tabs: [Tab] = []
    @Published var currentTabId: UUID?

    init() {
        // 初期タブを作成
        let initialTab = Tab()
        tabs = [initialTab]
        currentTabId = initialTab.id
    }

    var currentTab: Tab? {
        return tabs.first { $0.id == currentTabId }
    }

    var activeTabs: [Tab] {
        tabs
    }

    func createNewTab(url: String = "") {
        let newTab = Tab(url: url)
        tabs.append(newTab)
        currentTabId = newTab.id
    }

    func closeTab(_ tabId: UUID) {
        guard tabs.count > 1 else { return } // 最後のタブは閉じない

        if let index = tabs.firstIndex(where: { $0.id == tabId }) {
            tabs.remove(at: index)

            // 現在のタブを閉じた場合は、前のタブに切り替え
            if currentTabId == tabId {
                if index > 0 {
                    currentTabId = tabs[index - 1].id
                } else {
                    currentTabId = tabs.first?.id
                }
            }
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
}
