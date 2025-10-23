# BUG-030: 設定画面の「すべてのデータを削除」で履歴が削除されない

**ステータス**: ✅ 修正完了
**優先度**: 高
**発見日**: 2025-10-22
**修正日**: 2025-10-22

---

## 問題の詳細

### 症状
設定画面の「手動削除」セクションにある「すべてのデータを削除」ボタンをタップしても、閲覧履歴が削除されない。

### 再現手順
1. いくつかのウェブサイトを閲覧
2. 三点リーダ → 閲覧履歴を開く → 履歴が表示される
3. 設定画面を開く
4. 「手動削除」セクションの「すべてのデータを削除」をタップ
5. 確認ダイアログで「削除」を選択
6. 閲覧履歴画面を開く
7. **問題**: 履歴が残っている

### 期待される動作
- 閲覧履歴が完全に削除される
- 履歴画面に何も表示されない

---

## 原因分析

### 根本原因
`AutoDeleteService`の履歴削除処理が不完全だった。

**削除していたもの**:
- ✅ WebKitのデータストア（Cookie、キャッシュ、ローカルストレージ）

**削除していなかったもの**:
- ❌ Core Dataの閲覧履歴（`BrowsingHistoryManager`）

### コードの問題箇所

**AutoDeleteService.swift:247-255（修正前）**:
```swift
// 閲覧履歴を削除（WebKitのデータストア）
if deleteBrowsingHistory {
    clearBrowsingData()  // WebKitのデータストアのみ削除
    deletedItems.append("閲覧履歴")
}
```

`clearBrowsingData()`はWebKitのCookie、キャッシュなどは削除するが、Core Dataに保存された閲覧履歴は削除しない。

---

## 修正内容

### 修正ファイル
- `VanishBrowser/VanishBrowser/Services/AutoDeleteService.swift`

### 修正箇所1: `performAutoDelete()`

**修正前（行247-255）**:
```swift
// 閲覧履歴を削除（WebKitのデータストア）
if deleteBrowsingHistory {
    clearBrowsingData()
    deletedItems.append("閲覧履歴")
}
```

**修正後（行248-255）**:
```swift
// 閲覧履歴を削除（WebKitのデータストア + Core Data）
if deleteBrowsingHistory {
    // Core Dataの履歴を削除
    BrowsingHistoryManager.shared.clearHistory()

    // WebKitのデータストアも削除
    clearBrowsingData()
    deletedItems.append("閲覧履歴")
}
```

### 修正箇所2: `performManualDelete()`

**修正前（行320-324）**:
```swift
// 閲覧履歴を削除（WebKitのデータストア）
if history {
    clearBrowsingData()
    deletedItems.append("閲覧履歴")
}
```

**修正後（行325-332）**:
```swift
// 閲覧履歴を削除（WebKitのデータストア + Core Data）
if history {
    // Core Dataの履歴を削除
    BrowsingHistoryManager.shared.clearHistory()

    // WebKitのデータストアも削除
    clearBrowsingData()
    deletedItems.append("閲覧履歴")
}
```

---

## 修正後の動作

### 削除されるデータ

1. **Core Dataの閲覧履歴**
   - `BrowsingHistoryManager.shared.clearHistory()`
   - 閲覧履歴画面に表示される履歴エントリ

2. **WebKitのデータストア**
   - `clearBrowsingData()`
   - Cookie
   - キャッシュ
   - ローカルストレージ
   - IndexedDB
   - WebSQL

### 確認手順

1. ウェブサイトを数個閲覧
2. 閲覧履歴画面を開いて履歴が表示されることを確認
3. 設定 → 「すべてのデータを削除」をタップ
4. 確認ダイアログで「削除」を選択
5. 閲覧履歴画面を開く
6. **期待結果**: 履歴が空になっている

---

## 影響範囲

### 修正前の影響
- 手動削除で履歴が削除されない
- 自動削除でも履歴が削除されない
- プライバシー保護が不完全

### 修正後の動作
- ✅ 手動削除で履歴が完全に削除される
- ✅ 自動削除でも履歴が完全に削除される
- ✅ Core Data + WebKitの両方が削除される

---

## テスト

### 手動テスト
- [ ] ウェブサイト閲覧後、履歴が表示される
- [ ] 「すべてのデータを削除」実行
- [ ] 履歴が完全に削除される
- [ ] ダウンロードも削除される
- [ ] ブックマークも削除される

### 自動削除テスト
- [ ] 自動削除設定を「1時間後」に設定
- [ ] 1時間後に履歴が削除される

---

## 関連チケット

- なし（新規発見）

---

## 備考

この不具合は、履歴が2つの場所に保存されていることが原因：

1. **Core Data**: 履歴画面に表示するための構造化データ
2. **WebKit DataStore**: ブラウザエンジンのCookie/キャッシュ

両方を削除する必要があるが、実装時にCore Dataの削除が漏れていた。

今後、削除機能を実装する際は、すべてのデータソースを確認する必要がある。
