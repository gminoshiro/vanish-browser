# BUG-037: 動画もスワイプで移動できるようにする

**作成日**: 2025-10-28
**ステータス**: 🔴 対応中
**優先度**: High

---

## 問題

画像はスワイプで次の画像に移動できるが、動画は左右ボタンのまま。
動画も画像と同様にスワイプで移動できるようにしたい。

## 期待される動作

1. 動画一覧から動画をタップ
2. 動画プレーヤー表示
3. 左右スワイプで次/前の動画に移動
4. ツールバー表示状態で再生ボタン押下→全画面表示

## 技術的詳細

- FileViewerViewは画像のみスワイプ対応済み
- CustomVideoPlayerViewも同様の対応が必要
- TabViewまたは同等のスワイプジェスチャーを実装

## 関連ファイル

- [FileViewerView.swift](../../VanishBrowser/VanishBrowser/Views/FileViewerView.swift)
- [CustomVideoPlayerView.swift](../../VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift)

---

**最終更新**: 2025-10-28
