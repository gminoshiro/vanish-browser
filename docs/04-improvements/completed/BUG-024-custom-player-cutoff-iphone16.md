# BUG-024: iPhone16でカスタムプレーヤーが見切れる

🔴 P1 High | ✅ 修正完了

---

## 問題

iPhone16実機でカスタムプレーヤーが見切れている（左右上下すべて）。

---

## 原因

CustomVideoPlayerViewのSafe Area考慮不足。

---

## 対応方針

1. `.ignoresSafeArea()`の使用を見直し
2. コントロール部分にはSafe Areaのpaddingを適用
3. 動画表示部分のみ`.ignoresSafeArea()`を使用

---

## 関連ファイル

- [CustomVideoPlayerView.swift](../../VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift)

---

## 作成日

2025-10-19
