# BUG-025: 同じファイル名で異なる画像を保存すると上書きされる

🔴 P1 High | ✅ 修正完了

---

## 問題

異なる画像でファイル名が被った場合、常に最新の画像に変わってしまう。

---

## 期待動作

ファイル名が重複する場合は自動で連番を付ける（例: `image.jpg`, `image (1).jpg`, `image (2).jpg`）

---

## 対応方針

1. DownloadServiceで保存前にファイル名の重複チェック
2. 重複する場合は連番を付与
3. 既存のファイルを上書きしないように修正

---

## 関連ファイル

- [DownloadService.swift](../../VanishBrowser/VanishBrowser/Services/DownloadService.swift)

---

## 作成日

2025-10-19
