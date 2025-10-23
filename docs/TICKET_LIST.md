# チケット一覧

最終更新: 2025-10-23

---

## 🎯 ステータス

**✅ すべての既知バグ修正完了！**
**✅ App Storeリリース準備完了！**

---

## 🎉 最新セッションで完了した項目（2025-10-23）

### バグ修正
1. **[BUG-030](02-improvements/BUG-030-history-not-deleted-in-settings.md)** - 設定画面の「すべてのデータを削除」で履歴が削除されない問題修正 ✅
2. **[BUG-031](02-improvements/BUG-031-tab-close-button-not-working.md)** - タブの×ボタンが動作しない問題修正（通常タブ・プライベートタブ両対応） ✅

### 新機能
3. **FFmpegライセンス表示** - LGPL v2.1ライセンス情報、ソースコードリンク表示（App Store審査対応） ✅
4. **アプリレビュー依頼機能** - 10回目起動時に自動レビュー依頼、設定画面から手動レビュー可能 ✅

---

## 📋 完了済みチケット一覧

### 🔴 Critical/High優先度

- **[BUG-030](02-improvements/BUG-030-history-not-deleted-in-settings.md)** - 設定画面の履歴削除機能修正 ✅
- **[BUG-031](02-improvements/BUG-031-tab-close-button-not-working.md)** - タブ×ボタン修正 ✅
- **[BUG-029](02-improvements/BUG-029-url-navigation-not-working.md)** - URL入力・検索で画面遷移しない問題修正 ✅
- **[BUG-025](02-improvements/BUG-025-duplicate-filename-overwrite.md)** - 重複ファイル名連番対応（file (1).jpg形式） ✅
- **[BUG-024](02-improvements/BUG-024-custom-player-cutoff-iphone16.md)** - カスタムプレイヤー見切れ修正（Safe Area対応） ✅
- **[BUG-023](02-improvements/BUG-023-toolbar-cutoff-iphone16.md)** - ツールバー見切れ修正（Safe Area対応） ✅

### 🟡 Medium優先度

- **[FEATURE-009](02-improvements/FEATURE-009-toolbar-layout-redesign.md)** - ツールバーレイアウト再設計（タブボタン右端移動、三点リーダメニュー化） ✅
- **[FEATURE-008](02-improvements/FEATURE-008-image-swipe-navigation.md)** - 画像スワイプナビゲーション ✅
- **[FEATURE-007](02-improvements/FEATURE-007-video-navigation-controls.md)** - 動画ナビゲーションボタン ✅
- **[FEATURE-006](02-improvements/FEATURE-006-disable-extension-edit.md)** - 拡張子編集無効化 ✅
- **[BUG-027](02-improvements/BUG-027-toolbar-follows-keyboard.md)** - キーボード追従防止（.ignoresSafeArea(.keyboard)） ✅
- **[BUG-026](02-improvements/BUG-026-video-dl-button-appears-too-early.md)** - 動画DLボタン表示タイミング修正（readyState>=2条件追加） ✅

### 🟢 その他の完了項目

- **[FEATURE-010](02-improvements/FEATURE-010-share-extension.md)** - 写真アプリ共有対応 ✅
- **[FEATURE-005](02-improvements/FEATURE-005-auto-delete-timing-redesign.md)** - 自動削除タイミング見直し（90日追加） ✅
- **[FEATURE-002](02-improvements/FEATURE-002-password-ui-improvement.md)** - パスワードUI改善 ✅
- **[FEATURE-001](02-improvements/FEATURE-001-secure-default-browser.md)** - デフォルトブラウザ設定 ✅
- **[BUG-019](02-improvements/BUG-019-download-cancel-status-not-cleared.md)** - ダウンロードキャンセル後ステータス修正 ✅
- **[BUG-013](02-improvements/BUG-013-image-download-no-extension.md)** - 画像ダウンロード時拡張子保存 ✅
- **[BUG-012](02-improvements/BUG-012-auto-delete-ui-improvements.md)** - 自動削除UI改善 ✅
- **[BUG-011](02-improvements/BUG-011-auto-delete-targets.md)** - 自動削除対象紐付け ✅
- **[BUG-010](02-improvements/BUG-010-auto-delete-timing.md)** - 自動削除タイミング ✅
- **[BUG-009](02-improvements/BUG-009-password-setting.md)** - パスワード設定機能 ✅
- **[BUG-008](02-improvements/BUG-008-hls-to-mp4.md)** - HLS→MP4変換（FFmpeg使用） ✅
- **[BUG-007](02-improvements/BUG-007-video-download-timing.md)** - 動画再生時カスタムプレーヤー起動 ✅
- **[UX-001](02-improvements/UX-001-bookmark-and-toolbar-improvement.md)** - ブックマーク&ツールバー改善 ✅

---

## 📝 リリース準備状況

### ✅ 完了項目
- [x] 全バグ修正完了（BUG-030, BUG-031含む）
- [x] FFmpegライセンス表示追加（App Store審査対応）
- [x] アプリレビュー依頼機能実装
- [x] 実機テスト完了（iPhone 16）
- [x] ツールバーレイアウト最適化
- [x] プライベートブラウジング実装
- [x] 自動削除機能完成
- [x] HLS動画ダウンロード（MP4変換）

### 📋 リリース前確認事項
- [ ] App Store Connect登録
- [ ] スクリーンショット準備
- [ ] App Storeレビュー依頼のApp ID設定（SettingsView.swift:135）
- [ ] プライバシーポリシーURL設定
- [ ] 最終動作確認

---

## 🚀 次のステップ

1. **App Store Connect登録**
2. **スクリーンショット撮影**
3. **App Storeレビュー提出**

**リリース準備完了！**
