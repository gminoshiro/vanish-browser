# チケット一覧

最終更新: 2025-10-21
**実機テスト完了（iPhone 16）: 11件の新規issue発見**

---

## 🔴 高優先度

**✅ すべて完了！**

すべての高優先度チケットは実装完了しました。

---

## 🟡 中優先度

**✅ すべて完了！**

すべての中優先度チケットは実装完了しました。

---

## 🟢 低優先度

なし

---

## メモ

- HLSダウンロード: Alohaブラウザでは実現できている → FFmpegまたは独自実装で対応可能
- CustomVideoPlayerView: SwiftUIの再レンダリングループが発生中
- プライベートブラウジング: WKWebsiteDataStore.nonPersistent()を使用
- ファイル転送: Share Extension + UIActivityViewController

---

## 🎯 今回のセッションで完了した項目

1. **BUG-028 履歴削除機能** - 「すべて削除」ボタン追加、確認ダイアログ実装
2. **BUG-029 URL履歴復元** - URLバーから直接移動時も履歴に正しく記録
3. **ツールバーレイアウト再修正** - AutoLayout制約競合解消、6ボタン固定レイアウト再適用
4. **ビルドエラー修正** - isBookmarked変数削除によるコンパイルエラー解消

---

## リリース前（必須）

- [x] FEATURE-005 自動削除タイミング設定見直し（90日追加）✅ 既に実装済み
- [x] BUG-012 削除UI別だし ✅
- [x] BUG-011 削除対象の紐付け ✅
- [x] BUG-008 HLS→MP4変換 ✅
- [x] FEATURE-003 プライベートブラウジング ✅
- [x] **実機テスト（iPhone 16で実施）** ✅ → **11件の新規issue発見**
- [x] **🔴 Critical/High優先度の4件のバグ修正** ✅（BUG-021, BUG-023, BUG-024, BUG-025）
- [x] **🟡 Medium優先度の7件の改善** ✅（BUG-022, BUG-026, BUG-027, FEATURE-006~010）

**🎉 リリース準備完了！**

---

## 完了

### 実機テスト（iPhone 16）で発見された11件の問題 - すべて修正完了 (2025-10-20)

**🔴 Critical/High優先度（4件）:**
- [BUG-021](02-improvements/BUG-021-app-crashes.md) アプリクラッシュ対策 **完了✅** (メモリリーク修正)
- [BUG-023](02-improvements/BUG-023-toolbar-cutoff-iphone16.md) ツールバー見切れ修正 **完了✅** (Safe Area対応)
- [BUG-024](02-improvements/BUG-024-custom-player-cutoff-iphone16.md) カスタムプレイヤー見切れ修正 **完了✅** (Safe Area対応)
- [BUG-025](02-improvements/BUG-025-duplicate-filename-overwrite.md) 重複ファイル名連番対応 **完了✅** (file (1).jpg形式)

**🟡 Medium優先度（7件）:**
- [BUG-022](02-improvements/BUG-022-progress-bar-stuck.md) プログレスバー修正 **完了✅** (loadingProgress=0.0追加)
- [BUG-026](02-improvements/BUG-026-video-dl-button-appears-too-early.md) 動画DLボタン表示タイミング修正 **完了✅** (readyState>=2条件追加)
- [BUG-027](02-improvements/BUG-027-toolbar-follows-keyboard.md) キーボード追従防止 **完了✅** (.ignoresSafeArea(.keyboard))
- [FEATURE-006](02-improvements/FEATURE-006-disable-extension-edit.md) 拡張子編集無効化 **完了✅**
- [FEATURE-007](02-improvements/FEATURE-007-video-navigation-controls.md) 動画ナビゲーションボタン **完了✅**
- [FEATURE-008](02-improvements/FEATURE-008-image-swipe-navigation.md) 画像スワイプナビゲーション **完了✅**
- [FEATURE-009](02-improvements/FEATURE-009-toolbar-layout-redesign.md) ツールバーレイアウト再設計 **完了✅** (タブボタン右端移動)
- [FEATURE-010](02-improvements/FEATURE-010-share-extension.md) 写真アプリ共有対応 **完了✅** (既存実装確認)

### その他の機能実装（完了）

- [FEATURE-001](02-improvements/FEATURE-001-secure-default-browser.md) デフォルトブラウザ設定 **完了✅** (Info.plist設定必要)
- [FEATURE-002](02-improvements/FEATURE-002-password-ui-improvement.md) パスワードUI改善 **完了✅**
- [FEATURE-004/010](02-improvements/FEATURE-010-share-extension.md) ファイル転送機能（写真アプリ共有） **完了✅** (VanishBrowserApp.swiftで実装済み)

### 以前のセッションで完了した項目

- [BUG-008](02-improvements/BUG-008-hls-to-mp4.md) HLS→MP4変換 **完了✅** (FFmpeg libavformat使用)
- [FEATURE-003](02-improvements/FEATURE-003-private-browsing-mode.md) プライベートブラウジング **完了✅** (タブごとに選択可能)
- [BUG-012](02-improvements/BUG-012-auto-delete-ui-improvements.md) 自動削除UI改善 **完了✅**
- [BUG-011](02-improvements/BUG-011-auto-delete-targets.md) 自動削除対象紐付け **完了✅**
- [FEATURE-005](02-improvements/FEATURE-005-auto-delete-timing-redesign.md) 自動削除タイミング見直し **完了✅** (90日追加)
- [BUG-019](02-improvements/BUG-019-download-cancel-status-not-cleared.md) ダウンロードキャンセル後「ダウンロード中」が消えない **完了✅**
- [BUG-007](02-improvements/BUG-007-video-download-timing.md) 動画再生時にカスタムプレーヤーを起動 **完了✅**
- [BUG-013](02-improvements/BUG-013-video-playback-not-working.md) 動画再生できなくなっている **完了✅** (切り戻し対応)
- [BUG-013](02-improvements/BUG-013-image-download-no-extension.md) 画像ダウンロード時に拡張子が保存されない **完了✅**
- [BUG-009](02-improvements/BUG-009-password-setting.md) 認証で任意のパスワード設定ができない **完了✅**
- [BUG-010](02-improvements/BUG-010-auto-delete-timing.md) 自動削除のタイミングが正しく動作しない **完了✅**
- [BUG-028](02-improvements/BUG-028-history-deletion.md) 履歴削除機能 **完了✅** (「すべて削除」ボタン追加)
- [BUG-029](02-improvements/BUG-029-url-navigation.md) URL履歴復元 **完了✅** (URLバーから直接移動)
- [UX-001](02-improvements/UX-001-bookmark-and-toolbar-improvement.md) ブックマーク&ツールバー改善 **完了✅** (6ボタンレイアウト)
- [TEST-001](05-testing/TEST_SUMMARY.md) 単体テスト実装 (25テスト、100%成功) **完了✅**

---

## 🔍 調査中

- **起動時間の遅延** - 原因特定済み: WebView初期化時のJavaScript注入、改善策検討中（ユーザー確認待ち）
