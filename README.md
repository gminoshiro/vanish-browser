# Vanish Browser

**使わなければ消えるプライバシーブラウザ**

プライバシー保護を最優先に設計されたiOSブラウザ。日常的に使用している間は安全に保存され、長期間使わなかった場合のみ自動的に削除されます。

📋 **[開発管理](CLAUDE.md)** - 開発ルールと次にやること
📚 **[ドキュメント一覧](docs/INDEX.md)** - 全ドキュメントのインデックス

---

## 🎯 コンセプト

プライバシーを守りながら、万が一にも備える。

Vanish Browserは、**プライバシー保護を最優先**にしながら、長期未使用時の自動削除で万が一の事態にも備えるiOSブラウザです。

### 3つの特徴

#### 1. 完全プライバシー保護
- **生体認証ロック**: Face ID / Touch IDによる強固なアクセス制御
- **完全ローカル動作**: データは一切外部に送信されません
- **プライベートブラウジング**: 履歴を残さない安全なモード

#### 2. 使わなければ消える安心設計
- **長期未使用時の自動削除**: 90日間起動がなければ自動的にデータ削除
- **日常使いは安全**: 定期的に使用している間は問題なし
- **万が一の時も安心**: デジタル遺品として残らない副次的メリット

#### 3. 高機能ダウンロード
- **HLS→MP4変換**: ストリーミング動画をダウンロード可能
- **フォルダ管理**: ダウンロードファイルを整理
- **写真アプリに保存されない**: プライバシーを保護

---

## ✨ 主要機能

### プライバシー保護
- **🔐 生体認証**: Face ID / Touch ID + パスコード認証
- **🔒 プライベートブラウジング**: 履歴を残さないプライベートタブ
- **🌐 完全ローカル動作**: データ外部送信ゼロ

### 使わなければ消える
- **🕒 長期未使用時の自動削除**: 1日/7日/30日/90日から選択可能
- **⚠️ 削除前警告**: 起動時に削除までの残り日数を表示
- **✅ 日常使いは安全**: 定期的に使用している間は消えません

### 高機能
- **📥 ファイルダウンロード**: 動画・画像をフォルダ管理、HLS→MP4変換対応
- **🎬 カスタムプレーヤー**: インライン動画を独自プレーヤーで再生
- **📁 暗号化保存**: 写真アプリに保存されない安全な管理

---

## 🛠️ 技術スタック

| 項目 | 技術 |
|------|------|
| **言語** | Swift 5.9+ |
| **UI** | SwiftUI |
| **ブラウザエンジン** | WKWebView |
| **ローカルDB** | Core Data (暗号化対応) |
| **認証** | LocalAuthentication (生体認証) |
| **対応OS** | iOS 15.0+ |
| **アーキテクチャ** | MVVM + Combine |

### 依存ライブラリ

- **[FFmpeg-iOS](https://github.com/kewlbear/FFmpeg-iOS)** - HLS→MP4変換用 (GPL/LGPL)
- **[FFmpeg-iOS-Support](https://github.com/kewlbear/FFmpeg-iOS-Support)** - FFmpeg Swift ラッパー

⚠️ **重要**: FFmpegは GPL/LGPL ライセンスです。詳細は下記「ライセンス」セクション参照

---

## 📁 ディレクトリ構造

```
vanish-browser/
├── README.md                          # プロジェクト概要（本ファイル）
├── docs/                              # ドキュメント
│   ├── 01-business/                   # ビジネス関連
│   │   ├── monetization.md            # マネタイズ戦略
│   │   └── competitor-analysis.md     # 競合分析
│   ├── 02-product/                    # プロダクト関連
│   │   └── product-concept.md         # プロダクトコンセプト
│   ├── 03-requirements/               # 要件定義
│   │   ├── functional.md              # 機能要件
│   │   └── non-functional.md          # 非機能要件
│   ├── 04-design/                     # 設計
│   │   ├── architecture.md            # アーキテクチャ設計
│   │   ├── data-model.md              # データモデル
│   │   └── ui-flow.md                 # UI/UX設計
│   ├── 05-development/                # 開発
│   │   ├── tech-stack.md              # 技術スタック詳細
│   │   └── setup.md                   # 環境構築手順
│   ├── 06-testing/                    # テスト
│   │   └── test-plan.md               # テスト計画
│   ├── 07-launch/                     # リリース
│   │   ├── app-store-listing.md       # App Store掲載情報
│   │   └── privacy-policy.md          # プライバシーポリシー
│   └── 08-ai-prompts/                 # AI支援
│       └── code-generation.md         # コード生成プロンプト集
├── src/                               # ソースコード（後で追加）
│   └── VanishBrowser/
│       ├── Models/                    # データモデル
│       ├── Views/                     # SwiftUI Views
│       ├── ViewModels/                # ビジネスロジック
│       ├── Services/                  # サービス層
│       └── Utilities/                 # ユーティリティ
└── tests/                             # テストコード（後で追加）
```

---

## 🚀 開発環境セットアップ

### 必要な環境

- macOS 13.0以上
- Xcode 15.0以上
- Apple Developer Program（実機テスト・リリース時）

### セットアップ手順

```bash
# 1. リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/vanish-browser.git
cd vanish-browser

# 2. Xcodeプロジェクトを開く（プロジェクト作成後）
open VanishBrowser.xcodeproj

# 3. 実機またはシミュレータでビルド
# Xcode上で Cmd + R
```

詳細な手順は [docs/05-development/setup.md](docs/05-development/setup.md) を参照してください。

---

## 📊 開発状況

**実装完了率: 99%** - App Store提出準備完了

### 実装済み機能
- ✅ ブラウザコア機能（WKWebView、タブ管理、履歴）
- ✅ ダウンロード管理（画像・動画、HLS→MP4変換、フォルダ管理）
- ✅ カスタム動画プレーヤー（標準プレーヤー完全制御）
- ✅ 自動削除機能（1日/7日/30日/90日選択可能）
- ✅ 生体認証（Face ID / Touch ID + パスコード）
- ✅ プライベートブラウジング
- ✅ ブックマーク管理
- ✅ アプリレビュー依頼機能

### 次のステップ
1. **App Store Connect登録** - アプリ情報入力
2. **スクリーンショット作成** - 各種デバイス用
3. **審査提出**

詳細は [CLAUDE.md](CLAUDE.md) を参照してください。

---

## 💰 マネタイズ戦略

| フェーズ | 価格 | 期間 |
|---------|------|------|
| Phase 1 | 完全無料 | Week 1-4 |
| Phase 2 | ¥300買い切り | Month 2- |
| Phase 3 | ¥500/月サブスク（VPN追加） | Month 4- |

詳細は [docs/01-business/monetization.md](docs/01-business/monetization.md) を参照してください。

---

## 🎯 ターゲットユーザー

- **プライバシー重視層**: 個人情報保護を最優先する人
- **セキュリティ意識が高い人**: 安全なブラウジング環境を求める人
- **コンテンツダウンローダー**: 動画・画像を安全に保存したい人
- **万が一に備えたい人**: デジタル遺品対策を考える層（副次的）

---

## 🏆 競合との差別化

| ブラウザ | プライバシー | 削除タイミング | 価格 |
|---------|------------|---------------|------|
| Aloha | 終了時削除 | 終了時 | ¥500/月 |
| Brave | 広告ブロック | 終了時 | 無料 |
| Snowbunny | 終了時削除 | 終了時 | 無料 |
| **Vanish** | **生体認証+ローカル** | **使わなければ消える** | **¥300買い切り** |

**唯一の「使わなければ消える」プライバシーブラウザ** - 日常使いは安全、長期未使用時のみ自動削除。

---

## 🔒 セキュリティ・プライバシー

- ✅ **完全ローカル動作**: データは一切外部送信しない
- ✅ **プライベートブラウジング**: 履歴を残さないモード
- ✅ **iCloudバックアップ除外**: クラウドに残さない（予定）
- ✅ **トラッキングゼロ**: アクセス解析なし
- ✅ **生体認証**: Face ID / Touch IDによるアクセス制御

---

## 📄 ライセンス

### ⚠️ 重要: FFmpeg使用によるライセンス制約

このアプリケーションは **FFmpeg** を使用しているため、以下のライセンス制約があります。

**FFmpegのライセンス**
- FFmpegは **GPL (GNU General Public License)** または **LGPL (GNU Lesser General Public License)** でライセンスされています
- 使用している `FFmpeg-iOS` パッケージには **GPL** コンポーネントが含まれる可能性があります

**このアプリへの影響**
- ✅ **個人使用・オープンソースプロジェクト**: 問題ありません
- ⚠️ **App Store配信を予定する場合**:
  - このアプリも **GPLライセンス** として公開する必要があります
  - ソースコード全体の公開義務が発生します
  - または、**LGPL版のみ**でFFmpegを再ビルドする必要があります

**推奨される対応**
1. このリポジトリをオープンソース（GPLライセンス）として公開する
2. 商用利用の場合は、LGPL版FFmpegの使用を検討する
3. App Store審査時に適切なライセンス情報を記載する

詳細な説明は [HLS→MP4変換の実装詳細](docs/02-improvements/BUG-008-hls-to-mp4.md) を参照してください。

---

### アプリケーションコードのライセンス

MIT License

Copyright (c) 2025 Vanish Browser Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

**注意**: FFmpeg使用により、上記MITライセンスの代わりにGPL準拠が必要になる場合があります。

---

## 🤝 貢献

このプロジェクトはAIペアプログラミング（Cursor + Claude）で開発されています。

### 開発者

- **メイン開発者**: iOS初心者、Web開発経験者（TypeScript/Next.js、Java/Spring）
- **AIアシスタント**: Claude (Anthropic)

### 貢献方法

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

---

## 📞 お問い合わせ

- **GitHub Issues**: バグ報告・機能要望
- **Email**: (後で追加)
- **Twitter**: (後で追加)

---

## 🙏 謝辞

このプロジェクトは以下の技術・サービスを活用しています:

- Apple WKWebView
- SwiftUI Framework
- Anthropic Claude
- Cursor Editor

---

**最終更新**: 2025年10月24日
