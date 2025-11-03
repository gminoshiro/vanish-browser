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

folderが空の場合は`nil`ではなく`"未分類"`を設定するように変更：

```swift
bookmark.folder = folder.isEmpty ? "未分類" : folder  // ✅ デフォルト値を設定
```

## 影響

- フォルダを選択せずにブックマークを追加した場合、自動的に「未分類」フォルダに分類される
- ブックマーク追加が正常に動作するようになる

## テスト

- [ ] フォルダ選択なしでブックマーク追加 → 「未分類」に保存される
- [ ] フォルダ選択ありでブックマーク追加 → 選択したフォルダに保存される
- [ ] ブックマーク一覧で「未分類」フォルダが表示される

## 関連

- BUG-044: 自動削除設定でブックマークが意図せず削除される問題
