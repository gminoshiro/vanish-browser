# BUG-043: ブックマーク追加時に「folder is a required value」エラー

**作成日**: 2025-11-04
**ステータス**: 修正完了
**優先度**: High
**影響範囲**: ブックマーク機能全体

---

## 問題

ブックマークを追加しようとすると以下のエラーが発生し、ブックマークが保存できない：

```
ブックマーク追加エラー: Error Domain=NSCocoaErrorDomain Code=1570 "folder is a required value."
```

## 原因

1. Core Dataのモデルで`Bookmark.folder`がrequired（必須）に設定されている
2. BookmarkService.swiftの`addBookmark`関数で、folderが空文字列の場合に`nil`を設定していた
3. required属性との矛盾によりエラーが発生

**該当箇所**: [BookmarkService.swift:24](/Users/genfutoshi/vanish-browser/VanishBrowser/VanishBrowser/Services/BookmarkService.swift#L24)

```swift
bookmark.folder = folder.isEmpty ? nil : folder  // ❌ nilはNG
```

## 修正内容

### 修正1: folder必須エラーの解消

folderが空の場合は`nil`ではなく空文字列`""`を設定：

```swift
// BookmarkService.swift:25
bookmark.folder = folder.isEmpty ? "" : folder  // ✅ 空文字列を設定（ホーム直下）
```

**理由**: ダウンロード機能と同じ挙動（フォルダ未選択 = ホーム直下に表示）に統一

### 修正2: 空フォルダがフォルダ一覧に表示される問題

`fetchFolders()`で空文字列を除外：

```swift
// BookmarkService.swift:88-91
let folders = Set(bookmarks.compactMap { bookmark -> String? in
    guard let folder = bookmark.folder, !folder.isEmpty else { return nil }
    return folder
})
```

## 影響

- フォルダを選択せずにブックマークを追加した場合、ホーム直下に表示される
- ダウンロード機能と同じUI/UXになる
- ブックマーク追加が正常に動作する
- 空フォルダがフォルダ一覧に表示されなくなる

## テスト

- [x] フォルダ選択なしでブックマーク追加 → ホーム直下に保存される
- [x] フォルダ選択ありでブックマーク追加 → 選択したフォルダに保存される
- [x] ブックマーク一覧で空フォルダが表示されない

## 関連

- BUG-044: 自動削除設定でブックマークが意図せず削除される問題
