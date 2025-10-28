# BUG-026: 動画未再生時にDLボタンが表示される

🟡 P2 Medium | ✅ 修正完了（DLボタンを三点リーダ内に移動）

---

## 問題

動画再生する前から動画が乗っているサイトを閲覧するだけでも画面左下にDLボタンだけが出現している。しかし、DLできないのでトルツメしてほしい。

---

## 原因

JavaScriptの動画検出スクリプトが、動画要素が存在するだけでDLボタンを表示している。

---

## 対応方針

1. 動画検出の条件を厳格化（`readyState >= 2` など）
2. または、DLボタンを三点リーダ内に移動したので、左下のDLボタン表示を完全に削除

---

## 注意

既に三点リーダ内に「動画をダウンロード」メニューがあるため、左下のDLボタンは不要かもしれない。

---

## 関連ファイル

- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift)
- [BrowserViewModel.swift](../../VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift)

---

## 作成日

2025-10-19
