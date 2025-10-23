# BUG-027: キーボード表示時にツールバーが追従する

🟡 P2 Medium | ✅ 修正完了

---

## 問題

サイト内で入力しようとすると、下のフッターアイコンが上にくる。不必要なのでアイコンは追従しなくて良い。

---

## 期待動作

キーボード表示時もツールバーは画面下部に固定される。

---

## 対応方針

`.ignoresSafeArea(.keyboard)`をツールバーに適用する。

### 実装例

```swift
HStack {
    // ツールバーアイコン
}
.ignoresSafeArea(.keyboard, edges: .bottom)
```

---

## 関連ファイル

- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift)

---

## 作成日

2025-10-19
