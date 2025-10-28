# BUG-038: 動画再生中のタップでツールバー表示されないバグ

**作成日**: 2025-10-28
**ステータス**: 🔴 対応中
**優先度**: High

---

## 問題

動画再生中に画面タップしてもツールバーが表示されない。
画像と同様に、タップでツールバー表示/非表示を切り替えられるようにしたい。

## 期待される動作

1. 動画再生中に画面タップ
2. ツールバー（閉じる・ファイル名・共有）が表示される
3. もう一度タップで非表示

## 技術的詳細

- CustomVideoPlayerViewのタップジェスチャーが既存のコントロール表示と競合している可能性
- showControlsとshowToolbarの状態管理を整理する必要がある

## 関連ファイル

- [CustomVideoPlayerView.swift](../../VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift)

---

**最終更新**: 2025-10-28
