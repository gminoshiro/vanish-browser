# Vanish Browser

**デジタル遺品を残さない、プライバシー重視のiOSブラウザ**

90日間未起動で自動削除される、完全ローカル動作のセキュアブラウザアプリケーション。

---

## 🎯 コンセプト

もしもあなたが突然この世を去ったら、スマートフォンに残されたデータはどうなりますか？

Vanish Browserは「長期放置時の自動削除」機能により、デジタル遺品問題を根本から解決します。競合の「終了時削除」ブラウザとは異なり、**日常使いしながら、万が一に備える**ことができる唯一のソリューションです。

---

## ✨ 主要機能

- **🕒 自動削除機能**: 90日間未起動で全データを自動削除
- **🔔 削除前通知**: 削除7日前にリマインダー通知
- **📥 ファイルダウンロード**: 動画・画像・ドキュメントを安全に保存
- **🔐 暗号化ストレージ**: AES-256による強力な暗号化
- **👤 生体認証**: Face ID / Touch IDによるアクセス制御
- **🌐 プライバシー重視**: データ外部送信ゼロ、完全ローカル動作

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

**なし** - 標準APIのみで実装（App Store審査通過率向上、メンテナンス性確保）

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

## 📋 開発ロードマップ

### Phase 1: MVP開発（Week 1-4）
- [x] ドキュメント整備
- [ ] Xcodeプロジェクト作成
- [ ] ブラウザ機能実装
- [ ] ダウンロード機能実装
- [ ] 暗号化ストレージ実装
- [ ] 自動削除機能実装
- [ ] 生体認証実装
- [ ] TestFlight公開

### Phase 2: 有料化（Month 2-）
- [ ] ¥300買い切り設定
- [ ] App Store公開

### Phase 3: プレミアム機能追加（Month 4-）
- [ ] VPN統合
- [ ] サブスク機能（¥500/月）

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

- **30-50代男性**: デジタル遺品を気にする層
- **セキュリティ意識が高い人**: プライバシー重視
- **コンテンツダウンローダー**: 動画・画像保存ニーズ

---

## 🏆 競合との差別化

| ブラウザ | 削除タイミング | 価格 |
|---------|---------------|------|
| Aloha | 終了時 | ¥500/月 |
| Brave | 終了時 | 無料 |
| Snowbunny | 終了時 | 無料 |
| **Vanish** | **長期放置時（90日）** | **¥300買い切り** |

**唯一の「長期放置時自動削除」ブラウザ** - 日常使いしながら、万が一に備える。

---

## 🔒 セキュリティ・プライバシー

- ✅ **完全ローカル動作**: データは一切外部送信しない
- ✅ **AES-256暗号化**: 軍事レベルの暗号化
- ✅ **iCloudバックアップ除外**: クラウドに残さない
- ✅ **トラッキングゼロ**: アクセス解析なし
- ✅ **オープンソース化検討**: 透明性確保

---

## 📄 ライセンス

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

**最終更新**: 2025年10月8日
