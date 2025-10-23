# BUG-028: 履歴削除ONなのに削除されない

🔴 P1 High | ✅ 修正完了

---

## 問題

自動削除・手動削除で「閲覧履歴」をONにしても、実際には削除されない。

---

## 原因

`AutoDeleteService.clearBrowsingData()`が`WKWebsiteDataStore.default()`のみを削除していた。

各タブは独自のWebViewインスタンスを持ち、タブごとに異なるdataStoreを使用している：
- 通常タブ: `WKWebsiteDataStore.default()`
- プライベートタブ: `WKWebsiteDataStore.nonPersistent()`

そのため、**各タブのdataStoreも個別に削除する必要がある**。

---

## 修正内容

### 1. AutoDeleteService.swift

`clearBrowsingData()`を修正：

```swift
private func clearBrowsingData() {
    let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()

    // デフォルトdataStoreを削除（通常タブの履歴）
    let defaultStore = WKWebsiteDataStore.default()
    defaultStore.fetchDataRecords(ofTypes: dataTypes) { records in
        defaultStore.removeData(ofTypes: dataTypes, for: records) {
            print("🧹 デフォルトストアのブラウジングデータ削除完了")
        }
    }

    // すべてのタブのWebViewのdataStoreも削除（プライベート/通常両方）
    DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: NSNotification.Name("ClearAllTabsData"),
            object: nil,
            userInfo: nil
        )
        print("🧹 全タブのブラウジングデータ削除リクエスト送信")
    }
}
```

### 2. TabManager.swift

NotificationCenterで通知を受け取り、各タブのdataStoreを削除：

```swift
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
```

---

## 削除対象

- Cookies
- Cache
- LocalStorage
- SessionStorage
- IndexedDB
- WebSQL
- その他すべてのWebsiteデータ

**プライベートタブのデータも含む**

---

## テスト方法

1. 通常タブでWebサイトを閲覧
2. プライベートタブでWebサイトを閲覧
3. 自動削除設定で「閲覧履歴」をON
4. 手動削除を実行
5. すべてのタブでCookie・履歴が削除されることを確認

---

## 関連ファイル

- [AutoDeleteService.swift](../../VanishBrowser/VanishBrowser/Services/AutoDeleteService.swift#L260-L281)
- [TabManager.swift](../../VanishBrowser/VanishBrowser/ViewModels/TabManager.swift#L36-L49)

---

## 作成日

2025-10-20
