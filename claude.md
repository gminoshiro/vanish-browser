# VanishBrowser 開発管理

**最終更新: 2025-10-23**
**リリース準備度: 95%**

---

## 🚀 次にやること

- 動画や画像ファイル共有ができない？テストのやり方教えて
    共有アプリとしてでてこない



1. **App Store Connect登録** - アプリ情報入力、スクリーンショット
2. **App ID設定** - [SettingsView.swift:135](VanishBrowser/VanishBrowser/Views/SettingsView.swift#L135) の`YOUR_APP_ID`を置換
3. **最終確認** - バージョン番号、プライバシーポリシーURL
4. **審査提出** - Archive作成 → 提出

---

## 📋 開発ルール

### バグ発見時
1. **起票**: `docs/02-improvements/BUG-XXX-description.md`作成
2. **修正**: コード修正実装
3. **ドキュメント更新**: チケットに修正内容記載
4. **動作確認待ち**: ステータスを「要確認」に
5. **OK確認後**: コミット&プッシュ（粒度細かく）

### 機能追加時
1. **起票**: `docs/02-improvements/FEATURE-XXX-description.md`作成
2. **実装**: コード実装
3. **ドキュメント更新**: チケットに実装内容記載
4. **動作確認待ち**: ステータスを「要確認」に
5. **OK確認後**: コミット&プッシュ（粒度細かく）

### コミット
- **粒度**: チケット単位で細かく分割
- **メッセージ**: `fix: BUG-XXX ...` / `feat: FEATURE-XXX ...`
- **タイミング**: 確認OKが出たらすぐプッシュ（確認不要、自動実行）
- **バッチ禁止**: 複数チケットをまとめてコミットしない
- **自動コミット**: 動作確認OKが出たら、確認せず即座にコミット&プッシュ実行

### 作業進行
- **止まらない**: 確認待ちでも他のタスクを進める
- **質問する**: わからない点は正直に質問
- **勝手に判断しない**: 仕様変更は必ず確認
- **並行作業**: 独立したタスクは並行実行

---

## ✅ 完了済み（抜粋）

### 最新（2025-10-23）
- [BUG-030](docs/02-improvements/BUG-030-history-not-deleted-in-settings.md) - 履歴削除修正
- [BUG-031](docs/02-improvements/BUG-031-tab-close-button-not-working.md) - タブ×ボタン修正
- FFmpegライセンス表示
- レビュー依頼機能

### Critical修正済み
- [BUG-029](docs/02-improvements/BUG-029-url-navigation-not-working.md) - URL遷移
- [BUG-025](docs/02-improvements/BUG-025-duplicate-filename-overwrite.md) - 重複ファイル名
- [BUG-024](docs/02-improvements/BUG-024-custom-player-cutoff-iphone16.md) - プレイヤー見切れ
- [BUG-023](docs/02-improvements/BUG-023-toolbar-cutoff-iphone16.md) - ツールバー見切れ

### 主要機能実装済み
- [FEATURE-009](docs/02-improvements/FEATURE-009-toolbar-layout-redesign.md) - ツールバーレイアウト
- [FEATURE-008](docs/02-improvements/FEATURE-008-image-swipe-navigation.md) - 画像スワイプナビゲーション
- [FEATURE-007](docs/02-improvements/FEATURE-007-video-navigation-controls.md) - 動画ナビゲーション
- [FEATURE-006](docs/02-improvements/FEATURE-006-disable-extension-edit.md) - 拡張子編集無効化
- HLS→MP4変換（FFmpeg）
- プライベートブラウジング
- 自動削除（1日/7日/30日/90日）

---

## 🔧 重要ファイル

### コア
- [BrowserView.swift](VanishBrowser/VanishBrowser/Views/BrowserView.swift) - メインUI
- [BrowserViewModel.swift](VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift) - ブラウザロジック
- [TabManager.swift](VanishBrowser/VanishBrowser/ViewModels/TabManager.swift) - タブ管理
- [DownloadManager.swift](VanishBrowser/VanishBrowser/Services/DownloadManager.swift) - ダウンロード
- [AutoDeleteService.swift](VanishBrowser/VanishBrowser/Services/AutoDeleteService.swift) - 自動削除
- [ReviewManager.swift](VanishBrowser/VanishBrowser/Services/ReviewManager.swift) - レビュー依頼

### UI
- [TabManagerView.swift](VanishBrowser/VanishBrowser/Views/TabManagerView.swift) - タブ管理UI
- [CustomVideoPlayerView.swift](VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift) - 動画プレーヤー
- [SettingsView.swift](VanishBrowser/VanishBrowser/Views/SettingsView.swift) - 設定
- [LicenseView.swift](VanishBrowser/VanishBrowser/Views/LicenseView.swift) - ライセンス

---

## 🚀 リリース手順

```bash
# 1. Archive作成
Xcode > Product > Archive

# 2. App Store Connect
- アプリ情報入力
- スクリーンショットアップロード
- リリースノート記入

# 3. 審査提出
Organizer > Distribute App
```

---

**全機能実装完了。App Store提出準備のみ！**
