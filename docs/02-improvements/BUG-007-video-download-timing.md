# BUG-007: 動画再生直後のDLボタンが動作しない

🟡 P2 Medium | ⏳ 動作確認待ち

---

## 問題

動画再生開始直後（1-2秒以内）にDLボタンを押すと白い画面になりダウンロードできない。
数秒待つと正常にダウンロード可能。

---

## 実装内容

プレーヤーを閉じずにダイアログを表示する方式に変更しました。

### 変更点

1. **CustomVideoPlayerView.swift**: ダウンロードダイアログをプレーヤー内で表示
   - `showDownloadDialog` ステートを追加
   - DLボタン押下時にプレーヤーを閉じず、一時停止してダイアログ表示
   - `.sheet(isPresented: $showDownloadDialog)` でDownloadDialogViewを表示
   - ダウンロード開始後にプレーヤーを閉じる

2. **BrowserView.swift**: HLSダウンロード開始通知を追加
   - `StartHLSDownload` 通知を受信
   - `handleHLSDownload()` を呼び出し

### 効果

- プレーヤーとBrowserViewの遷移タイミングの問題を解消
- ダイアログ表示時の白画面問題を修正
- すぐにDLボタンを押しても正常に動作

---

## 関連ファイル

- [CustomVideoPlayerView.swift](../../VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift)
- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift)
