# Vanish Browser - プロジェクト概要

**最終更新: 2025-10-29**
**ステータス: v1.0 App Store審査提出済み**

---

## 📱 アプリ概要

**Vanish Browser（バニッシュブラウザ）** は、プライバシー保護を最優先に設計されたiOSブラウザアプリです。

### コンセプト

**"使わなければ消える、プライバシーブラウザ"**

- 日常的に使用している間は安全に保存
- 長期間使わなかった場合のみ自動的に削除
- 万が一の事故や病気で使えなくなった時、プライバシーを守る

### ターゲットユーザー

- プライバシーを重視する一般ユーザー
- アダルトコンテンツを安全に管理したいユーザー
- デジタル遺品対策を考えている方
- 突然の事故・病気でスマホを他人に見られるリスクを懸念する方

---

## 🎯 主な機能

### 1. 自動削除機能（コア機能）

| 設定 | 削除タイミング | 用途 |
|------|--------------|------|
| 1日 | アプリ未起動1日後 | 最高レベルのプライバシー |
| 7日 | アプリ未起動7日後 | 週1程度の利用 |
| 30日 | アプリ未起動30日後 | 月1程度の利用 |
| 90日 | アプリ未起動90日後 | たまに使う（デフォルト） |
| オフ | 削除しない | 通常のブラウザとして |

**動作:**
- 設定日数を超えると、次回起動時に全データ（履歴・ダウンロード・ブックマーク）を自動削除
- 削除3日前にアラート表示（「あと3日で削除されます」）

### 2. 生体認証

- **Face ID / Touch ID** + パスコード
- アプリ起動時の認証
- 設定でオン/オフ可能

### 3. ブラウザ機能

- **プライベートブラウジング**: 履歴を残さないモード
- **タブ管理**: 複数タブ対応
- **ブックマーク**: お気に入りサイト保存
- **履歴管理**: 閲覧履歴の表示・削除

### 4. ダウンロード管理

- **画像・動画ダウンロード**: Webページから直接保存
- **HLS→MP4変換**: ストリーミング動画をMP4に変換してダウンロード（FFmpeg使用）
- **フォルダ管理**: ダウンロードファイルをフォルダで整理
- **カスタムプレーヤー**: アプリ内で動画・画像を再生
- **ファイル共有**: Photosアプリなどから動画・画像を受け取り

### 5. プライバシー保護

- **完全ローカル動作**: データ外部送信ゼロ
- **データ暗号化**: Core Dataで安全に保存
- **履歴削除**: ブラウザ履歴の一括削除
- **Cookie削除**: Webサイトのトラッキング防止

---

## 🛠️ 技術スタック

### 言語・フレームワーク

| 項目 | 技術 | バージョン |
|------|------|----------|
| **言語** | Swift | 5.9+ |
| **UI** | SwiftUI | - |
| **ブラウザエンジン** | WKWebView | - |
| **ローカルDB** | Core Data | - |
| **認証** | LocalAuthentication | - |
| **対応OS** | iOS | 15.0+ |
| **アーキテクチャ** | MVVM + Combine | - |

### 依存ライブラリ

| ライブラリ | 用途 | ライセンス |
|----------|------|----------|
| [FFmpeg-iOS](https://github.com/kewlbear/FFmpeg-iOS) | HLS→MP4変換 | GPL/LGPL |

---

## 📂 プロジェクト構成

```
VanishBrowser/
├── VanishBrowser/              # メインアプリ
│   ├── VanishBrowserApp.swift  # アプリエントリポイント
│   ├── Views/                  # UI層
│   │   ├── BrowserView.swift          # ブラウザメイン画面
│   │   ├── DownloadListView.swift     # ダウンロード一覧
│   │   ├── CustomVideoPlayerView.swift # 動画プレーヤー
│   │   ├── FileViewerView.swift       # 画像・動画ビューアー
│   │   ├── SettingsView.swift         # 設定画面
│   │   ├── TabManagerView.swift       # タブ管理
│   │   └── AuthenticationView.swift   # 生体認証
│   ├── ViewModels/             # ビジネスロジック
│   │   ├── BrowserViewModel.swift     # ブラウザロジック
│   │   └── TabManager.swift           # タブ管理
│   ├── Services/               # サービス層
│   │   ├── DownloadService.swift      # ダウンロード管理
│   │   ├── DownloadManager.swift      # ダウンロード実行
│   │   ├── HLSDownloader.swift        # HLS→MP4変換
│   │   ├── AutoDeleteService.swift    # 自動削除
│   │   ├── AppSettingsService.swift   # 設定管理
│   │   ├── ReviewManager.swift        # レビュー依頼
│   │   └── Persistence.swift          # Core Data
│   └── VanishBrowser.xcdatamodeld/   # Core Dataモデル
├── docs/                       # ドキュメント
│   ├── 01-product/            # プロダクト定義
│   ├── 02-development/        # 開発ガイド
│   ├── 03-launch/             # リリース手順
│   └── 04-improvements/       # 改善チケット
├── CLAUDE.md                   # 開発管理（AI向け）
├── README.md                   # プロジェクト説明
└── PROJECT_OVERVIEW.md         # 本ファイル
```

---

## 📊 開発状況

### v1.0（2025-10-29提出）

**実装完了率: 100%**

#### 実装済み機能
- ✅ ブラウザコア（WKWebView、タブ管理、履歴、ブックマーク）
- ✅ ダウンロード管理（画像・動画、HLS→MP4変換、フォルダ管理）
- ✅ カスタム動画プレーヤー（スワイプナビゲーション、フルスクリーン）
- ✅ カスタム画像ビューアー（スワイプナビゲーション、フルスクリーン）
- ✅ 自動削除機能（1日/7日/30日/90日選択可）
- ✅ 生体認証（Face ID / Touch ID + パスコード）
- ✅ プライベートブラウジング
- ✅ 共有拡張機能（Photosから動画・画像受け取り）
- ✅ レビュー依頼機能（アプリ起動5回目、30日後、90日後）
- ✅ ライセンス表示（FFmpeg GPL/LGPL）

#### 主要バグ修正
- ✅ [BUG-039](docs/04-improvements/BUG-039-file-move-to-home-not-working.md) - ファイル移動後のUI更新問題
- ✅ [BUG-036](docs/04-improvements/completed/BUG-036-custom-player-cutoff-iphone16.md) - iPhone 16でのプレーヤー見切れ
- ✅ [BUG-030](docs/04-improvements/completed/BUG-030-history-not-deleted-in-settings.md) - 履歴削除が動作しない
- ✅ [BUG-031](docs/04-improvements/completed/BUG-031-tab-close-button-not-working.md) - タブ×ボタンが動作しない

#### リリース済みタグ
- `v1.0` (2025-10-29) - App Store提出版

### v1.1（次期バージョン予定）

#### 未実装機能
- [ ] [BUG-037](docs/04-improvements/BUG-037-video-swipe-navigation.md) - 動画スワイプナビゲーション
- [ ] [BUG-038](docs/04-improvements/BUG-038-video-toolbar-tap-bug.md) - 動画ツールバータップバグ
- [ ] 動画プレーヤー閉じるアニメーション改善

---

## 🔄 Git運用フロー

### ブランチ戦略

```
main (本番リリース版、保護) ← タグ: v1.0, v1.1
  ↑ PR
develop (開発ブランチ、デフォルト) ← 日常作業
  ↑ 直接コミット
feature/xxx, fix/xxx (作業ブランチ)
```

### 開発フロー

1. **日常開発**: `develop` ブランチで作業
2. **動作確認**: ユーザー確認OKをもらう
3. **コミット&プッシュ**: `develop` にプッシュ
4. **リリース**: `develop` → `main` へPR作成
5. **タグ作成**: `main` にマージ後、バージョンタグ作成

詳細: [docs/02-development/git-workflow.md](docs/02-development/git-workflow.md)

---

## 📋 開発ルール

### バグ発見時

1. **起票**: `docs/04-improvements/BUG-XXX-description.md`作成
2. **修正**: コード修正実装
3. **ドキュメント更新**: チケットに修正内容記載
4. **動作確認**: ステータスを「要確認」に
5. **コミット**: 動作確認OK後、`develop` にプッシュ

### コミットメッセージ規約

```
<type>: <subject>

<body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Type:**
- `fix`: バグ修正
- `feat`: 新機能
- `docs`: ドキュメント
- `refactor`: リファクタリング
- `test`: テスト追加
- `chore`: ビルド設定など

---

## 🚀 リリース手順

### 1. Archive作成

```bash
# Xcodeで実行
Product > Archive
```

### 2. App Store Connect提出

```bash
# Organizerから
Distribute App > App Store Connect > Upload
```

### 3. タグ作成

```bash
git checkout main
git pull
git tag -a v1.1 -m "App Store提出版 v1.1"
git push origin v1.1
```

詳細: [docs/03-launch/app-store-submission.md](docs/03-launch/app-store-submission.md)

---

## 📄 ライセンス

### アプリライセンス

本アプリケーションのソースコードは独自ライセンスです。

### 依存ライブラリライセンス

- **FFmpeg-iOS**: GPL 2.0 / LGPL 2.1
  - HLS→MP4変換機能で使用
  - アプリ内のライセンス表示で明記

---

## 📞 連絡先

- **開発者**: 簑城玄太 (Gen Minoshiro)
- **リポジトリ**: https://github.com/gminoshiro/vanish-browser
- **App Store**: (審査中)

---

## 📚 参考ドキュメント

### プロダクト
- [プロダクトコンセプト](docs/01-product/product-concept.md)
- [ターゲットユーザー](docs/01-product/target-users.md)
- [収益化戦略](docs/01-product/monetization.md)

### 開発
- [技術スタック](docs/02-development/tech-stack.md)
- [セットアップ手順](docs/02-development/setup.md)
- [テスト計画](docs/02-development/test-plan.md)
- [Git運用フロー](docs/02-development/git-workflow.md)

### リリース
- [App Store提出手順](docs/03-launch/app-store-submission.md)
- [スクリーンショット](docs/03-launch/screenshots.md)
- [プライバシーポリシー](docs/03-launch/privacy-policy.md)

### 改善チケット
- [完了済みチケット](docs/04-improvements/completed/)
- [未実装チケット](docs/04-improvements/)

---

**このドキュメントは、AIチャットや新規参加者がプロジェクト全体を理解するための概要です。**
