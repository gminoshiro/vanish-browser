# チケット一覧

最終更新: 2025-10-17

---

## 🔴 高

- [BUG-014](02-improvements/BUG-014-custom-player-infinite-loop.md) CustomVideoPlayerViewの無限再初期化ループ **未対応**
- [BUG-008](02-improvements/BUG-008-hls-to-mp4.md) HLS動画のMP4ダウンロード非対応 **実装方法要検討（FFmpeg等）**
- [BUG-012](02-improvements/BUG-012-auto-delete-ui-improvements.md) 自動削除機能のUI改善 **動作確認待ち**
- [BUG-011](02-improvements/BUG-011-auto-delete-targets.md) 自動削除と削除対象が紐づいていない **動作確認待ち**

---

## 🟡 中

- [FEATURE-002](02-improvements/FEATURE-002-password-ui-improvement.md) パスワード入力画面のUI改善 **動作確認待ち**
- [FEATURE-001](02-improvements/FEATURE-001-secure-default-browser.md) デフォルトブラウザをセキュリティの高いブラウザに設定 **動作確認待ち (Info.plist設定必要)**

---

## 🟢 低

なし

---

## メモ

- HLSダウンロード: Alohaブラウザでは実現できている → FFmpegまたは独自実装で対応可能
- CustomVideoPlayerView: SwiftUIの再レンダリングループが発生中

---

## リリース前

- [ ] BUG-014 CustomVideoPlayerView無限ループ修正
- [ ] BUG-012 削除UI別だし
- [ ] BUG-011 削除対象の紐付け
- [ ] 実機テスト

---

## 完了

- [BUG-007](02-improvements/BUG-007-video-download-timing.md) 動画再生時にカスタムプレーヤーを起動 **完了✅**
- [BUG-013](02-improvements/BUG-013-video-playback-not-working.md) 動画再生できなくなっている **完了✅** (切り戻し対応)
- [BUG-013](02-improvements/BUG-013-image-download-no-extension.md) 画像ダウンロード時に拡張子が保存されない **完了✅**
- [BUG-009](02-improvements/BUG-009-password-setting.md) 認証で任意のパスワード設定ができない **完了✅**
- [BUG-010](02-improvements/BUG-010-auto-delete-timing.md) 自動削除のタイミングが正しく動作しない **完了✅**
- [TEST-001](05-testing/TEST_SUMMARY.md) 単体テスト実装 (25テスト、100%成功) **完了✅**
