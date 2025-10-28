# VanishBrowser ドキュメントインデックス

**最終更新: 2025-10-28**

---

## 📋 開発管理（最重要）

- **[CLAUDE.md](../CLAUDE.md)** - 開発ルール・次にやること・完了済みチケット
- **[README.md](../README.md)** - プロジェクト概要・技術スタック

---

## 🎯 プロダクト・ビジネス

- [プロダクトコンセプト](01-product/product-concept.md) - コンセプト詳細・ターゲット・自動削除仕様
- [競合分析](01-product/competitor-analysis.md) - 他ブラウザとの比較
- [マネタイズ戦略](01-product/monetization.md) - 価格設定・収益モデル

---

## 🛠️ 開発・技術

- [環境構築手順](02-development/setup.md) - 開発環境のセットアップ
- [技術スタック詳細](02-development/tech-stack.md) - 使用技術の詳細
- [テスト計画](02-development/test-plan.md) - テスト項目・手順

---

## 🚀 リリース・App Store

- [App Store掲載情報](03-launch/app-store-listing.md) - タイトル・説明文・スクリーンショット
- [プライバシーポリシー](03-launch/privacy-policy.md) - プライバシーポリシー全文

---

## 🐛 完了済みチケット

完了したバグ修正・機能追加は [02-improvements/completed/](02-improvements/completed/) を参照してください。

主要な完了済みチケット：
- [BUG-036](02-improvements/completed/BUG-036-video-player-controls-cutoff-iphone16.md) - カスタム動画プレーヤーのコントロール見切れ修正
- [BUG-035](02-improvements/completed/BUG-035-biometric-fallback-passcode.md) - 生体認証フォールバック
- [BUG-033](02-improvements/completed/BUG-033-private-browsing-history-saved.md) - プライベートブラウザ履歴保存
- [BUG-034](02-improvements/completed/BUG-034-tab-toggle-wrong-on-private.md) - タブトグル
- [FEATURE-010](02-improvements/completed/FEATURE-010-share-extension.md) - 共有拡張機能
- [FEATURE-009](02-improvements/completed/FEATURE-009-toolbar-layout-redesign.md) - ツールバーレイアウト
- [FEATURE-007/008](02-improvements/completed/FEATURE-007-video-navigation-controls.md) - 動画/画像ナビゲーション

---

## 📁 ディレクトリ構造

```
docs/
├── INDEX.md                    # このファイル
├── 01-product/                 # プロダクト・ビジネス戦略
│   ├── product-concept.md
│   ├── competitor-analysis.md
│   └── monetization.md
├── 02-development/             # 開発・テスト
│   ├── setup.md
│   ├── tech-stack.md
│   └── test-plan.md
├── 02-improvements/            # バグ・機能チケット
│   └── completed/              # 完了済みチケット
└── 03-launch/                  # リリース関連
    ├── app-store-listing.md
    └── privacy-policy.md
```

---

**開発を続ける場合は [CLAUDE.md](../CLAUDE.md) を参照してください。**
