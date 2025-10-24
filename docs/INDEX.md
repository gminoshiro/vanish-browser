# VanishBrowser ドキュメントインデックス

**最終更新: 2025-10-24**

---

## 📋 開発管理（最重要）

- **[CLAUDE.md](../CLAUDE.md)** - 開発ルール・次にやること・完了済みチケット
- **[README.md](../README.md)** - プロジェクト概要・技術スタック

---

## 🎯 ビジネス・プロダクト

### ビジネス戦略
- [競合分析](01-business/competitor-analysis.md) - 他ブラウザとの比較
- [マネタイズ戦略](01-business/monetization.md) - 価格設定・収益モデル

### プロダクトコンセプト
- [プロダクトコンセプト](02-product/product-concept.md) - コンセプト詳細・ターゲット

---

## 🛠️ 開発・技術

### セットアップ
- [環境構築手順](05-development/setup.md) - 開発環境のセットアップ
- [技術スタック詳細](05-development/tech-stack.md) - 使用技術の詳細
- [デフォルトブラウザ設定](03-setup/DEFAULT_BROWSER_SETUP.md) - デフォルトブラウザ機能の実装

---

## 🚀 リリース・App Store

### App Store申請
- [App Store掲載情報](07-launch/app-store-listing.md) - タイトル・説明文・スクリーンショット
- [プライバシーポリシー](07-launch/privacy-policy.md) - プライバシーポリシー全文

---

## 🐛 完了済みチケット

完了したバグ修正・機能追加は [02-improvements/completed/](02-improvements/completed/) を参照してください。

主要な完了済みチケット：
- [BUG-033](02-improvements/completed/BUG-033-private-browsing-history-saved.md) - プライベートブラウザ履歴保存
- [BUG-034](02-improvements/completed/BUG-034-tab-toggle-wrong-on-private.md) - タブトグル
- [BUG-035](02-improvements/completed/BUG-035-biometric-fallback-passcode.md) - 生体認証フォールバック
- [FEATURE-009](02-improvements/completed/FEATURE-009-toolbar-layout-redesign.md) - ツールバーレイアウト
- [FEATURE-007/008](02-improvements/completed/FEATURE-007-video-navigation-controls.md) - 動画/画像ナビゲーション

---

## 🧪 テスト

- [テスト計画](06-testing/test-plan.md) - テスト項目・手順

---

## 📁 ディレクトリ構造

```
docs/
├── INDEX.md                    # このファイル
├── 01-business/                # ビジネス戦略
├── 02-improvements/            # バグ・機能チケット
│   └── completed/              # 完了済みチケット
├── 02-product/                 # プロダクト
├── 03-setup/                   # セットアップガイド
├── 05-development/             # 開発ガイド
├── 06-testing/                 # テスト
└── 07-launch/                  # リリース
```

---

**開発を続ける場合は [CLAUDE.md](../CLAUDE.md) を参照してください。**
