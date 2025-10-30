# FEATURE-010: タブの永続化と自動削除

**ステータス**: ✅ 実装完了（要動作確認）
**優先度**: High
**作成日**: 2025-10-30
**完了日**: 2025-10-30
**担当**: Claude

---

## 要件

### 概要
アプリ再起動時にタブを復元し、自動削除設定でタブも削除できるようにする。

### 現状の問題
- アプリを閉じると、すべてのタブが消える
- 次回起動時に新規タブ1つから開始
- Safari、Alohaなどの他ブラウザではタブが保持される

### 期待動作
1. **タブの永続化**
   - アプリを閉じても、タブの状態（URL、タイトル、プライベート/通常）を保存
   - 次回起動時に前回のタブをすべて復元
   - プライベートタブも通常タブも同じように永続化

2. **自動削除設定の拡張**
   - 削除対象に「タブ」トグルを追加
   - 閲覧履歴/ダウンロード/ブックマークと同じグルーピング
   - トグルON時、設定期間（1日/7日/30日/90日）経過後にタブを削除

---

## 仕様

### タブの永続化

#### 保存するデータ
```swift
struct PersistedTab: Codable {
    let id: String  // UUID
    let url: String
    let title: String
    let isPrivate: Bool
    let createdAt: Date  // 自動削除用
}
```

#### 保存タイミング
- タブ作成時
- タブURL変更時
- タブタイトル変更時
- タブ削除時
- アプリ終了時（`sceneDidEnterBackground`）

#### 復元タイミング
- TabManager初期化時
- 保存されたタブがあれば復元、なければ新規タブ1つ作成

#### 保存先
- UserDefaults
- キー: `"savedTabs"`

### 自動削除設定

#### 設定画面の追加項目
```
削除対象
├─ 閲覧履歴 [トグル]
├─ ダウンロード [トグル]
├─ ブックマーク [トグル]
└─ タブ [トグル] ← 新規追加
```

#### 削除ロジック
- AutoDeleteServiceで定期的にチェック
- `createdAt`から設定期間経過したタブを削除
- プライベートタブも通常タブも同じ条件で削除

---

## 実装計画

### 1. タブ永続化機能

#### TabManager.swift
- [ ] `PersistedTab`構造体を定義
- [ ] `saveTabs()`メソッド追加 - タブをUserDefaultsに保存
- [ ] `loadTabs()`メソッド追加 - UserDefaultsからタブを復元
- [ ] `init()`で`loadTabs()`を呼び出し
- [ ] `createNewTab()`、`closeTab()`、`updateTab()`で`saveTabs()`を呼び出し

#### Tab.swift
- [ ] `createdAt: Date`プロパティ追加

#### VanishBrowserApp.swift
- [ ] `sceneDidEnterBackground`で`saveTabs()`を呼び出し

### 2. 設定画面の拡張

#### SettingsView.swift
- [ ] 「タブ」トグルを追加
- [ ] `@AppStorage("autoDeleteTabs")`追加

### 3. 自動削除機能の拡張

#### AutoDeleteService.swift
- [ ] `deleteOldTabs()`メソッド追加
- [ ] `performAutoDelete()`で`deleteOldTabs()`を呼び出し

---

## 実装詳細

### TabManager.swift

```swift
// PersistedTab構造体
private struct PersistedTab: Codable {
    let id: String
    let url: String
    let title: String
    let isPrivate: Bool
    let createdAt: Date
}

// 保存
private func saveTabs() {
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
    }
}

// 復元
private func loadTabs() {
    guard let data = UserDefaults.standard.data(forKey: "savedTabs"),
          let persistedTabs = try? JSONDecoder().decode([PersistedTab].self, from: data),
          !persistedTabs.isEmpty else {
        // 保存されたタブがない場合は新規タブ作成
        let initialTab = Tab()
        tabs = [initialTab]
        currentTabId = initialTab.id
        return
    }

    // タブを復元
    tabs = persistedTabs.map { persisted in
        let tab = Tab(
            url: persisted.url,
            isPrivate: persisted.isPrivate
        )
        tab.id = UUID(uuidString: persisted.id) ?? UUID()
        tab.title = persisted.title
        tab.createdAt = persisted.createdAt
        return tab
    }

    currentTabId = tabs.first?.id
}
```

### Tab.swift

```swift
class Tab: Identifiable, ObservableObject {
    let id: UUID
    @Published var url: String
    @Published var title: String
    let isPrivate: Bool
    let createdAt: Date  // 追加

    init(url: String = "", isPrivate: Bool = false) {
        self.id = UUID()
        self.url = url
        self.title = ""
        self.isPrivate = isPrivate
        self.createdAt = Date()  // 追加
        // ...
    }
}
```

### SettingsView.swift

```swift
// 削除対象セクション
Section {
    Toggle("閲覧履歴", isOn: $autoDeleteHistory)
    Toggle("ダウンロード", isOn: $autoDeleteDownloads)
    Toggle("ブックマーク", isOn: $autoDeleteBookmarks)
    Toggle("タブ", isOn: $autoDeleteTabs)  // 追加
} header: {
    Text("削除対象")
}
```

### AutoDeleteService.swift

```swift
private func deleteOldTabs() {
    guard autoDeleteEnabled, autoDeleteTabs else { return }

    let cutoffDate = Calendar.current.date(
        byAdding: .day,
        value: -autoDeleteDays,
        to: Date()
    ) ?? Date()

    // 古いタブを削除
    tabManager.tabs.removeAll { tab in
        tab.createdAt < cutoffDate
    }

    // 最低1つのタブは残す
    if tabManager.tabs.isEmpty {
        let newTab = Tab()
        tabManager.tabs.append(newTab)
        tabManager.currentTabId = newTab.id
    }

    tabManager.saveTabs()
}
```

---

## テスト計画

### タブ永続化
- [ ] アプリを閉じて再起動 → タブが復元される
- [ ] 通常タブとプライベートタブを混在 → 両方復元される
- [ ] タブがない状態で起動 → 新規タブ1つ作成

### 自動削除
- [ ] タブトグルON、1日設定 → 1日経過後にタブが削除される
- [ ] タブトグルOFF → タブは削除されない
- [ ] すべてのタブが削除対象 → 最低1つの新規タブが残る

---

## 注意事項

### プライバシー考慮
- プライベートタブも永続化されるため、完全なプライバシーではない
- ただし、自動削除設定でタブを定期削除できる

### パフォーマンス
- タブが大量（100個以上）になるとUserDefaultsのパフォーマンスが低下する可能性
- 必要に応じてFileManagerでの保存に変更

---

## 関連ファイル
- `VanishBrowser/VanishBrowser/ViewModels/TabManager.swift`
- `VanishBrowser/VanishBrowser/Models/Tab.swift`
- `VanishBrowser/VanishBrowser/Views/SettingsView.swift`
- `VanishBrowser/VanishBrowser/Services/AutoDeleteService.swift`

---

## コミット
- [ ] 実装コミット: `feat: FEATURE-010 タブの永続化と自動削除`
