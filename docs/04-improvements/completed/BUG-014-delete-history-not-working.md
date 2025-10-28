# BUG-014: 今すぐ削除で履歴削除が動作していない

🔴 P0 Critical | ✅ 修正完了

---

## 問題

「今すぐ削除」機能で履歴削除が動作していない。

---

## 要件

### 1. 削除対象のチェックに紐づいた削除処理

**優先度**: 高

- 現状: 削除処理が正しく動作していない
- 要望: チェックボックスで選択された項目のみを削除したい

### 2. 削除前の確認モーダル

**優先度**: 低

- 現状: いきなり削除が実行される
- 要望: 「今すぐ削除」実行時のみ確認モーダルを表示したい
- 理由: 誤操作防止のため、一度ユーザーの確認を取りたい

---

## 実装内容

### 変更点

#### 1. AutoDeleteSettingsView.swift

「今すぐ削除」ボタン押下時に確認ダイアログを表示するように変更：

- 削除対象の選択状態を保持する `@State` 変数を追加
- ボタン押下時に確認ダイアログを表示
- ダイアログ内で削除対象を確認して削除を実行

**追加したState変数**:
```swift
@State private var showDeleteConfirmation = false
@State private var confirmDeleteHistory = false
@State private var confirmDeleteDownloads = false
@State private var confirmDeleteBookmarks = false
```

**確認ダイアログ**:
```swift
.alert("削除確認", isPresented: $showDeleteConfirmation) {
    Button("キャンセル", role: .cancel) {}
    Button("削除", role: .destructive) {
        executeDelete()
        dismiss()
    }
} message: {
    Text(getDeleteConfirmationMessage())
}
```

#### 2. AutoDeleteService.swift

選択された項目のみを削除する新しいメソッド `performManualDelete` を追加：

```swift
func performManualDelete(history: Bool, downloads: Bool, bookmarks: Bool) {
    // 選択された項目のみ削除
    if downloads {
        let files = DownloadService.shared.fetchDownloadedFiles()
        for file in files {
            DownloadService.shared.deleteFile(file)
        }
        // 空のフォルダを削除
        DownloadService.shared.removeEmptyFolders()
    }

    if bookmarks {
        let bookmarks = BookmarkService.shared.fetchBookmarks()
        for bookmark in bookmarks {
            BookmarkService.shared.deleteBookmark(bookmark)
        }
    }

    if history {
        clearBrowsingData()
    }
}
```

#### 3. DownloadService.swift

空のフォルダを削除する `removeEmptyFolders()` メソッドを追加：

```swift
func removeEmptyFolders() {
    let downloadsDirURL = downloadsDirectory
    let contents = try fileManager.contentsOfDirectory(at: downloadsDirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])

    for folderURL in contents {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            continue
        }

        let folderContents = try fileManager.contentsOfDirectory(atPath: folderURL.path)
        if folderContents.isEmpty {
            try fileManager.removeItem(at: folderURL)
        }
    }
}
```

---

## 効果

1. ✅ **削除前に確認ダイアログが表示される**
   - 誤操作防止
   - 削除対象が明示される

2. ✅ **トグル設定に基づいた削除処理**
   - 「削除対象」セクションのトグル設定に従って削除される
   - 選択されていない項目は削除されない

3. ✅ **空フォルダの自動削除**
   - ダウンロード削除後、空になったフォルダも自動的に削除される

---

## テスト方法

1. 自動削除設定画面を開く
2. 「削除対象」でいくつかの項目をON/OFFする
3. 「今すぐ削除」ボタンを押す
4. 確認ダイアログが表示されることを確認
5. 削除対象が正しく表示されることを確認
6. 「削除」ボタンを押して削除が実行されることを確認

---

## 関連ファイル

- [AutoDeleteSettingsView.swift](../../VanishBrowser/VanishBrowser/Views/AutoDeleteSettingsView.swift)
- [AutoDeleteService.swift](../../VanishBrowser/VanishBrowser/Services/AutoDeleteService.swift)

---

## 作成日

2025-10-17

## 完了日

2025-10-17
