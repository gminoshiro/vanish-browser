# BUG-023: iPhone16で下部ツールバーが見切れる

🔴 P1 High | ✅ 修正完了

---

## 問題

iPhone16実機で下部ボタンが見切れている（左右どちらも）。

---

## 原因

Safe Areaの考慮不足、またはiPhone16の画面サイズに対応していない可能性。

---

## 対応方針

1. `.padding(.bottom, geometry.safeAreaInsets.bottom)`を追加
2. `.edgesIgnoringSafeArea()`の使用箇所を確認
3. iPhone16シミュレーターでレイアウト確認

---

## 関連ファイル

- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift)

---

## 作成日

2025-10-19
