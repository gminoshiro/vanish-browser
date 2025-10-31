# VanishBrowser 開発管理

**最終更新: 2025-10-29**
**リリース準備度: 100%**
**現在のブランチ: develop**

---

## 🚀 次にやること

1. **App Store審査待ち** - v1.0提出済み
2. **次期バージョン開発** - developブランチで継続

---

## 📋 開発ルール

### Git運用フロー ⭐ 重要

**ブランチ戦略:**
```
main (本番リリース版、保護) ← タグ: v1.0, v1.1
  ↑ PR
develop (開発ブランチ、デフォルト) ← 日常作業
  ↑ 直接コミット
feature/xxx, fix/xxx (作業ブランチ)
```

**詳細:** [docs/02-development/git-workflow.md](docs/02-development/git-workflow.md)

**基本フロー:**
1. `develop` ブランチで日常開発
2. 動作確認OK後、コミット&プッシュ（**ユーザー確認必須**）
3. リリース時のみ `develop` → `main` へPR
4. `main` にマージ後、バージョンタグ作成

### バグ発見時
1. **起票**: `docs/04-improvements/BUG-XXX-description.md`作成
2. **ブランチ**: `develop` で作業（または `fix/BUG-XXX` ブランチ作成）
3. **修正**: コード修正実装
4. **ドキュメント更新**: チケットに修正内容記載
5. **動作確認待ち**: ステータスを「要確認」に
6. **OK確認後**: コミット&プッシュ（**ユーザー確認必須**）

### 機能追加時
1. **起票**: `docs/04-improvements/FEATURE-XXX-description.md`作成
2. **ブランチ**: `develop` で作業（または `feature/FEATURE-XXX` ブランチ作成）
3. **実装**: コード実装
4. **ドキュメント更新**: チケットに実装内容記載
5. **動作確認待ち**: ステータスを「要確認」に
6. **OK確認後**: コミット&プッシュ（**ユーザー確認必須**）

### コミット＆プッシュ ⚠️ 重要
- **プッシュ前に確認**: 必ずユーザーに「動作確認OK」をもらってからプッシュ
- **粒度**: チケット単位で細かく分割
- **メッセージ**: `fix: BUG-XXX ...` / `feat: FEATURE-XXX ...`
- **ブランチ**: `develop` にプッシュ（`main` は保護されているのでPRのみ）
- **バッチ禁止**: 複数チケットをまとめてコミットしない
- **プッシュ後の確認**: ユーザーに確認してもらい、OKが出たら次のステップへ

### mainへのマージ ⭐ 重要
**プッシュ完了後、自動的にmainマージはせず、必ず確認を取る:**

1. **プッシュ完了**: `develop` へコミット&プッシュ
2. **確認を取る**: 「プッシュ完了しました。PR作成してmainにマージしてよいですか？（バージョンアップが必要な場合は先に対応します）」
3. **ユーザー確認待ち**: OKが出るまで待機
4. **バージョン対応**: 必要に応じてバージョン番号を更新→プッシュ→再確認
5. **PR作成&マージ**: 確認OK後に `develop` → `main` へPR作成→マージ

```bash
# PR作成とマージ（ユーザー確認OK後のみ実行）
gh pr create --base main --head develop --title "..." --body "..."
gh pr merge <PR番号> --merge --delete-branch=false
```

**重要**: バージョンアップが必要なケースが多いので、プッシュ後は一度立ち止まって確認する

### 作業進行
- **止まらない**: 確認待ちでも他のタスクを進める
- **質問する**: わからない点は正直に質問
- **勝手に判断しない**: 仕様変更は必ず確認
- **並行作業**: 独立したタスクは並行実行

---

## 🎨 UI/UXガイドライン

### ナビゲーションパターン

VanishBrowserでは、画面の表示方法に応じて統一されたナビゲーションパターンを使用します。

#### 1️⃣ モーダル/シート表示（`.sheet`）

**用途**: 独立した作業フロー、設定画面、一覧画面など

**ボタン配置:**
- **左上**: 「閉じる」ボタン（必須）
- **右上**: アクションボタン（削除、追加など、任意）

**実装例:**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button("閉じる") { dismiss() }
    }
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("削除") { /* ... */ }
    }
}
```

**該当画面:**
- SettingsView（設定）
- CookieManagerView（Cookie管理）
- BrowsingHistoryView（閲覧履歴）
- BookmarkListView（ブックマーク一覧）
- DownloadListView（ダウンロード一覧）
- PasscodeSettingsView（パスコード設定）
- DownloadDialogView（ダウンロードダイアログ）

#### 2️⃣ NavigationLink遷移

**用途**: 階層的な画面遷移、設定のサブ画面など

**ボタン配置:**
- **左上**: システム標準の「← 戻る」ボタン（自動表示）
- **右上**: なし（または必要に応じてアクション）
- **重要**: `.navigationBarBackButtonHidden(true)` は使用禁止

**実装例:**
```swift
NavigationLink(destination: SubView()) {
    Text("サブ画面へ")
}
// SubView側では特別な設定不要（戻るボタンは自動）
```

**該当画面:**
- AutoDeleteSettingsView（自動削除設定）
- LicenseView（ライセンス）

#### 3️⃣ 全画面表示（`.fullScreenCover` / カスタムUI）

**用途**: 動画プレーヤー、画像ビューアーなど没入型コンテンツ

**ボタン配置:**
- **左上**: 「×」ボタン（`xmark.circle.fill`）
- **右上**: 共有ボタン（`square.and.arrow.up`）

**実装例:**
```swift
HStack {
    Button(action: { dismiss() }) {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 32))
            .foregroundColor(.white)
    }
    Spacer()
    ShareLink(item: url) {
        Image(systemName: "square.and.arrow.up")
            .font(.system(size: 28))
            .foregroundColor(.white)
    }
}
```

**該当画面:**
- CustomVideoPlayerView（動画プレーヤー）
- FileViewerView（画像ビューアー）

---

### セクション間の余白

**List内のセクション:**
- `.listStyle(.insetGrouped)` を使用
- セクションヘッダーに `.padding(.top, 8)` を追加

**実装例:**
```swift
List {
    Section(header: Text("一般").padding(.top, 8)) {
        // ...
    }
    Section(header: Text("セキュリティ").padding(.top, 8)) {
        // ...
    }
}
.listStyle(.insetGrouped)
```

---

### 説明文の配置

**原則**: 説明文はセクションのfooter（下部）に配置

**理由**: ユーザーは項目を見てから説明を読むため、下部の方が自然

**実装例:**
```swift
Section(header: Text("削除する内容"), footer: Text("選択した項目が自動的に削除されます")) {
    Toggle("閲覧履歴", isOn: $deleteBrowsingHistory)
    Toggle("ダウンロード", isOn: $deleteDownloads)
}
```

---

## 📝 リリース後の改善課題

### UI/UX改善
- **動画プレーヤーの閉じるアニメーション**: 動画プレーヤーを閉じる際に一時的にFileViewerViewの透明画面が見える（0.1秒程度）。完全に黒画面にするか、アニメーション時間を調整することで改善可能。
- [BUG-037](docs/04-improvements/BUG-037-video-swipe-navigation.md) - 動画スワイプナビゲーション（未実装）
- [BUG-038](docs/04-improvements/BUG-038-video-toolbar-tap-bug.md) - 動画ツールバータップバグ（未実装）

---

## ✅ 完了済み（抜粋）

### 最新（2025-10-27）
- 動画プレーヤーのUI改善（×ボタン左上統一、共有ボタン右上）
- DL済み動画の共有機能実装（ShareSheet使用）
- 動画プレーヤーを閉じたときにダウンロード一覧に戻るよう修正
- 画像・動画ファイルの受信機能（Document Types設定）

### 2025-10-23
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
- [DownloadListView.swift](VanishBrowser/VanishBrowser/Views/DownloadListView.swift) - ダウンロード一覧
- [SettingsView.swift](VanishBrowser/VanishBrowser/Views/SettingsView.swift) - 設定
- [LicenseView.swift](VanishBrowser/VanishBrowser/Views/LicenseView.swift) - ライセンス

### ドキュメント
- [docs/INDEX.md](docs/INDEX.md) - ドキュメント一覧
- [docs/01-product/](docs/01-product/) - プロダクト・ビジネス戦略
- [docs/02-development/](docs/02-development/) - 開発・テスト
- [docs/03-launch/](docs/03-launch/) - リリース関連

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

**✅ 全機能実装完了！リリース準備OK！**

**最終動作確認済み項目:**
- ✅ 動画ダウンロード & 再生
- ✅ 画像ダウンロード & 表示
- ✅ ファイル共有（動画・画像）
- ✅ カスタム動画プレーヤー（×ボタン左上、共有ボタン右上）
- ✅ ダウンロード一覧からの動画再生
- ✅ 自動削除機能
- ✅ プライベートブラウジング
- ✅ タブ管理
- ✅ ブックマーク
- ✅ 履歴管理
