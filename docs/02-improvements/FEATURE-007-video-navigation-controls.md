# FEATURE-007: ダウンロード内動画再生で前後ナビゲーション

🟡 P2 Medium | ✅ 実装済み

---

## 要望

ダウンロード内動画再生で前後に進めるボタンが欲しい。そのボタン押下で次や前の動画へ。

---

## 期待動作

カスタムプレーヤーに「前へ」「次へ」ボタンを追加し、同じフォルダ内の動画を連続再生可能にする。

---

## 実装方針

1. CustomVideoPlayerViewに現在のインデックス情報を渡す
2. 「前へ」「次へ」ボタンを追加
3. ボタン押下で前後の動画URLに切り替え

---

## 関連ファイル

- [CustomVideoPlayerView.swift](../../VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift)
- [DownloadsView.swift](../../VanishBrowser/VanishBrowser/Views/DownloadsView.swift)

---

## 作成日

2025-10-19
