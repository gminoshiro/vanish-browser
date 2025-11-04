# Vanish Browser

**使わなければ消えるプライバシーブラウザ**

プライバシー保護を最優先に設計されたiOSブラウザ。日常的に使用している間は安全に保存され、長期間使わなかった場合のみ自動的に削除されます。

---

## 🎯 主な特徴

- **使わなければ消える** - 1日/7日/30日/90日の自動削除設定
- **生体認証** - Face ID / Touch ID + パスコード
- **プライベートブラウジング** - 履歴を残さない
- **HLS→MP4変換** - ストリーミング動画のダウンロード
- **完全ローカル動作** - データ外部送信ゼロ

---

## 🛠️ 技術スタック

| 項目 | 技術 |
|------|------|
| **言語** | Swift 5.9+ |
| **UI** | SwiftUI |
| **ブラウザエンジン** | WKWebView |
| **ローカルDB** | Core Data |
| **認証** | LocalAuthentication |
| **対応OS** | iOS 15.0+ |
| **アーキテクチャ** | MVVM + Combine |

### 依存ライブラリ
- **[FFmpeg-iOS](https://github.com/kewlbear/FFmpeg-iOS)** - HLS→MP4変換用 (GPL/LGPL)

---

## 📊 開発状況

**実装完了率: 100%** - App Store提出準備完了

### 実装済み機能
- ✅ ブラウザコア（WKWebView、タブ管理、履歴、ブックマーク）
- ✅ ダウンロード管理（画像・動画、HLS→MP4変換、フォルダ管理）
- ✅ カスタム動画プレーヤー
- ✅ 自動削除機能（1日/7日/30日/90日選択可）
- ✅ 生体認証（Face ID / Touch ID + パスコード）
- ✅ プライベートブラウジング
- ✅ 共有拡張機能（Photosから動画・画像受け取り）

### 次のステップ
1. App Store Connect登録
2. スクリーンショット作成
3. 審査提出

---

## 🏆 競合との差別化

| ブラウザ | 削除タイミング | 価格 |
|---------|---------------|------|
| Aloha | 終了時 | ¥500/月 |
| Brave | 終了時 | 無料 |
| Snowbunny | 終了時 | 無料 |
| **Vanish** | **使わなければ消える** | **¥300買い切り（予定）** |

**唯一の「使わなければ消える」プライバシーブラウザ**

詳細は [競合分析](docs/01-product/competitor-analysis.md) を参照

---

## 📁 ディレクトリ構造

```
vanish-browser/
├── README.md              # プロジェクト概要（本ファイル）
├── DEV.md                 # 開発管理・次にやること
├── docs/                  # ドキュメント
│   ├── 01-product/       # プロダクト・ビジネス戦略
│   ├── 02-development/   # 開発・テスト
│   ├── 03-launch/        # リリース関連
│   └── 04-improvements/  # 完了済みチケット
└── VanishBrowser/        # Xcodeプロジェクト
    └── VanishBrowser/
        ├── Models/
        ├── Views/
        ├── ViewModels/
        ├── Services/
        └── Utilities/
```

---

## 📚 ドキュメント

開発管理・詳細情報は以下を参照：

- **[DEV.md](DEV.md)** - 開発管理・開発ルール・重要ファイル一覧
- **[docs/01-product/](docs/01-product/)** - プロダクトコンセプト・競合分析・マネタイズ
- **[docs/02-development/](docs/02-development/)** - 環境構築・技術スタック・テスト計画
- **[docs/03-launch/](docs/03-launch/)** - App Store掲載情報・プライバシーポリシー

---

## 🚀 環境構築

```bash
# リポジトリをクローン
git clone https://github.com/gminoshiro/vanish-browser.git
cd vanish-browser

# Xcodeプロジェクトを開く
open VanishBrowser/VanishBrowser.xcodeproj

# 実機またはシミュレータでビルド (Cmd + R)
```

詳細は [環境構築手順](docs/02-development/setup.md) を参照

---

## 📄 ライセンス

MIT License (アプリケーションコード)

⚠️ **FFmpeg使用のため GPL/LGPL 制約あり** - 詳細はアプリ内「ライセンス」画面参照

---

## 🤝 貢献

このプロジェクトはAIペアプログラミング（Claude Code）で開発されています。

### 貢献方法
1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット
4. ブランチにプッシュ
5. プルリクエストを作成

---

**最終更新**: 2025-10-28
