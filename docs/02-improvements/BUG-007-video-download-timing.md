# BUG-007: 動画再生開始直後のダウンロード問題

## 概要
動画を再生してすぐにDLボタンを押すとダウンロードができない。少し待ってから押すとダウンロードできる。

## 再現手順
1. サイトで動画を再生
2. 再生開始直後（数秒以内）にDLボタンを押す
3. ダウンロードダイアログは表示されるが、ダウンロードができない
4. 一度閉じて、動画を再度再生し、少し時間が経ってからDLボタンを押す
5. ダウンロードが正常に動作する

## 調査結果
- ログを確認したところ、通知の送受信は正常に動作している
- `showDownloadDialog = true` に設定されており、ダイアログは表示される
- AVPlayerの準備状態（`✅ AVPlayer: 再生準備完了`）が関係している可能性がある
- 動画再生直後はAVPlayerがまだ完全に準備できていない可能性

## 想定される原因
- AVPlayerの初期化が完了していない状態でダウンロード処理が実行される
- ネットワーク接続が不安定
- URLの取得タイミングの問題

## 優先度
低（回避策あり：少し待ってからDLボタンを押す）

## 対応案
1. AVPlayerの準備完了を待ってからDLボタンを有効化
2. DLボタンにローディング状態を追加
3. ダウンロード失敗時のリトライ機能

## 関連ファイル
- `/VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift` (106-119行目)
- `/VanishBrowser/VanishBrowser/Views/BrowserView.swift` (497-515行目)

## ログ
```
🎬 CustomVideoPlayerView初期化
🎬 videoURL: https://www.home-movie.biz/mov/hts-samp003.mp4
🎥 VideoPlayerViewModel初期化
⚠️ AVPlayer: ステータス不明
✅ CustomAVPlayerView作成完了
🎥 動画の長さ: 14.581233333333333秒
✅ AVPlayer: 再生準備完了
📥 DLボタン押下
📤 ShowDownloadDialog通知送信
📨 ShowDownloadDialog通知受信
📨 showDownloadDialog = true に設定
```
