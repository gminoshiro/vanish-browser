# VanishBrowser 開発管理

**最終更新: 2025-11-01**
**リリース準備度: 100%**
**現在のブランチ: develop**
**審査状況: v1.0.2 審査中（2025-10-31提出）**

---

## 🚀 次にやること

1. **App Store審査待ち** - v1.0.2審査中
2. **v1.0.3準備** - developブランチでUI/UX改善完了
   - 自動削除設定画面のUI改善
   - ホーム画面のYahoo! JAPAN対応
   - ビデオプレーヤーの再生ボタン中央配置
   - 動画プレーヤーの閉じるアニメーション改善
   - ブックマークのタイトル省略表示

---

## 🔍 調査中: blob: URLダウンロード機能（ZIPファイル対応）

**目標**: Hitomi.laなどのサイトで使用されているblob: URLのZIPファイルをダウンロードできるようにする（Alohaブラウザと同じ動作）

### 現状の問題

**症状**:
- blob: URLのZIPダウンロードボタンをクリックすると文字化けページに遷移してしまう
- ダウンロードダイアログが表示されない

**ユーザーの期待動作（Alohaブラウザ）**:
1. ZIPダウンロードボタンをクリック
2. ダウンロードダイアログが表示される（フォルダ選択）
3. フォルダを選択してダウンロード完了
4. ZIPファイルがダウンロード一覧に表示される
5. ZIPファイルをタップして解凍

### 実装済みの内容

#### 1. blob: URLナビゲーションのブロック ✅

**ファイル**: [BrowserViewModel.swift:924-976](VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift#L924)

```swift
func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
             decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let url = navigationAction.request.url {
        // blob: URLへのナビゲーションをブロック（文字化けページ表示を防ぐ）
        if url.scheme == "blob" {
            print("🚫 blob: URL navigation blocked: \(url.absoluteString)")

            // JavaScriptでblob:データを取得してダウンロード
            let urlString = url.absoluteString.replacingOccurrences(of: "'", with: "\\'")
            let js = """
            (function() {
                var blobUrl = '\(urlString)';
                fetch(blobUrl)
                    .then(function(response) { return response.blob(); })
                    .then(function(blob) {
                        var reader = new FileReader();
                        reader.onloadend = function() {
                            var base64 = reader.result.split(',')[1];
                            var fileName = 'download.zip';
                            if (blob.type.includes('zip')) fileName = 'archive.zip';

                            window.webkit.messageHandlers.blobDownload.postMessage({
                                url: blobUrl,
                                fileName: fileName,
                                data: base64,
                                mimeType: blob.type,
                                size: blob.size
                            });
                        };
                        reader.readAsDataURL(blob);
                    });
            })();
            """

            webView.evaluateJavaScript(js, completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
    }
    decisionHandler(.allow)
}
```

**動作**: ✅ blob: URLへの遷移をキャンセルして文字化けページ表示を防ぐ

#### 2. JavaScriptでのblob: URL検出とデータ取得 ✅

**ファイル**: [BrowserViewModel.swift:386-468](VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift#L386)

```swift
let blobDownloadScript = WKUserScript(
    source: """
    (function() {
        // <a>タグのクリックを監視
        document.addEventListener('click', function(e) {
            var target = e.target;
            while (target && target.tagName !== 'A') {
                target = target.parentElement;
            }

            if (!target || target.tagName !== 'A') return;

            var href = target.href;
            var download = target.download || target.getAttribute('download');

            // blob: URLまたはdownload属性付きリンクの場合
            if (href && (href.startsWith('blob:') || download)) {
                e.preventDefault();
                e.stopPropagation();

                var fileName = download || href.split('/').pop() || 'download.zip';

                if (href.startsWith('blob:')) {
                    fetch(href)
                        .then(function(response) { return response.blob(); })
                        .then(function(blob) {
                            var reader = new FileReader();
                            reader.onloadend = function() {
                                var base64 = reader.result.split(',')[1];
                                window.webkit.messageHandlers.blobDownload.postMessage({
                                    url: href,
                                    fileName: fileName,
                                    data: base64,
                                    mimeType: blob.type,
                                    size: blob.size
                                });
                            };
                            reader.readAsDataURL(blob);
                        });
                }
                return false;
            }
        }, true);
    })();
    """,
    injectionTime: .atDocumentStart,
    forMainFrameOnly: false
)
```

**動作**: ✅ JavaScriptでblob: URLリンクのクリックを検出し、Blobデータを取得してBase64エンコード

#### 3. Swiftでのblob: URLデータ処理 ✅

**ファイル**: [BrowserViewModel.swift:1189-1237](VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift#L1189)

```swift
else if message.name == "blobDownload",
          let dict = message.body as? [String: Any],
          let fileName = dict["fileName"] as? String {

    DispatchQueue.main.async {
        print("📦 Blob download detected: \(fileName)")

        // blob: URLの場合はbase64データがある
        if let base64Data = dict["data"] as? String,
           let data = Data(base64Encoded: base64Data) {

            print("✅ Blob data received: \(data.count) bytes")

            // 一時ファイルに保存
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent(fileName)

            do {
                try data.write(to: tempFile)
                print("✅ Blob saved to temp file: \(tempFile.path)")

                // ダウンロードダイアログを表示
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowDownloadDialog"),
                    object: nil,
                    userInfo: [
                        "url": tempFile,
                        "fileName": fileName
                    ]
                )
            } catch {
                print("❌ Failed to save blob: \(error)")
            }
        }
    }
}
```

**動作**: ✅ Base64データをデコードして一時ファイルに保存し、ダウンロードダイアログ表示通知を送信

#### 4. WKDownloadDelegate実装 ✅

**ファイル**: [BrowserViewModel.swift:964-1015](VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift#L964)

```swift
@available(iOS 14.5, *)
extension BrowserViewModel: WKDownloadDelegate {
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent(suggestedFilename)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        completionHandler(destinationURL)
    }

    func downloadDidFinish(_ download: WKDownload) {
        if let originalURL = download.originalRequest?.url {
            let fileName = originalURL.lastPathComponent
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowDownloadDialog"),
                    object: nil,
                    userInfo: ["url": originalURL, "fileName": fileName]
                )
            }
        }
    }
}
```

**動作**: ✅ iOS 14.5以降でWKDownloadを使用した標準ダウンロード処理

### 動作確認ログ

```
🚫 blob: URL navigation blocked: blob:https://hitomi.la/bf1cda70-9023-4d5a-a18a-8834d65bac2c
📦 Blob download detected: archive.zip
✅ Blob data received: 7047576 bytes
✅ Blob saved to temp file: /Users/.../tmp/archive.zip
📨 ShowDownloadDialog通知受信
📨 URL: file:///.../tmp/archive.zip, fileName: archive.zip
📨 設定前 - pendingDownloadURL: nil, showDownloadDialog: false
📨 設定後 - pendingDownloadURL: Optional(file:///.../tmp/archive.zip), showDownloadDialog: true
📨 0.1秒後確認 - pendingDownloadURL: Optional(file:///.../tmp/archive.zip), showDownloadDialog: true
```

**結果**: ✅ blob: URLブロック成功、✅ データ取得成功、✅ 一時ファイル保存成功、✅ 通知送信成功、✅ フラグ設定成功

### 未解決の問題: ダイアログが表示されない ❌

**症状**:
- `showDownloadDialog = true`が設定される
- `pendingDownloadURL`も正しく設定される
- しかし画面が白いまま（ダイアログが表示されない）
- `🔍 downloadDialogView appeared`のログが出ない（ビューが描画されていない）

**試した解決策**:

#### 1. シートの順序変更
**問題**: SwiftUIで複数の`.sheet(isPresented:)`を定義すると最後の1つしか機能しない
**試行**: `showDownloadDialog`のシートを最後に移動
**結果**: ❌ 効果なし

#### 2. `.fullScreenCover()`への変更
**ファイル**: [BrowserView.swift:504-506](VanishBrowser/VanishBrowser/Views/BrowserView.swift#L504)

```swift
.fullScreenCover(isPresented: $showDownloadDialog) {
    downloadDialogView
}
```

**理由**: `.fullScreenCover()`は`.sheet()`と別の階層なので競合しない
**結果**: ❌ 効果なし（まだテスト中）

### 技術的な調査結果

#### SwiftUIの複数シート問題

**発見**: SwiftUIでは同じビュー階層に複数の`.sheet(isPresented:)`を定義すると、**最後の1つしか機能しない**という制限がある

**現在のBrowserViewのシート構造**:
```swift
.sheet(isPresented: $showBookmarks) { ... }
.sheet(isPresented: $showDownloads) { ... }
.sheet(isPresented: $showSettings) { ... }
.sheet(isPresented: $showAutoDeleteSettings) { ... }
.sheet(isPresented: $showCookieManager) { ... }
.sheet(isPresented: $showBrowsingHistory) { ... }
.sheet(isPresented: $showBookmarkFolderSelection) { ... }
.sheet(isPresented: $showShareSheet) { ... }
.fullScreenCover(isPresented: $showDownloadDialog) { ... }  // ← ここ
```

**問題**: 8個のシートが定義されており、動作が不安定

**推奨される解決策**:
```swift
enum SheetType: Identifiable {
    case bookmarks
    case downloads
    case settings
    case downloadDialog(url: URL, fileName: String)
    // ...

    var id: String { /* ... */ }
}

@State private var activeSheet: SheetType?

.sheet(item: $activeSheet) { sheetType in
    switch sheetType {
    case .bookmarks: BookmarkListView()
    case .downloads: DownloadListView()
    case .downloadDialog(let url, let fileName):
        DownloadDialogView(...)
    // ...
    }
}
```

**実装の難しさ**: 全てのシート呼び出し箇所を変更する必要があり、大規模な変更になる

### 次のステップ（調査継続時）

#### オプション1: enum統合方式（推奨、時間かかる）
1. `SheetType` enumを定義
2. すべての`show*`フラグを`activeSheet: SheetType?`に統合
3. 全てのシート呼び出し箇所を更新
4. テスト

**見積もり**: 30-60分、影響範囲が広い

#### オプション2: ダイアログだけ別階層に分離（簡易）
1. DownloadDialogViewを`ZStack`の最上位に配置
2. `showDownloadDialog`で表示/非表示を制御
3. `.sheet()`を使わない独自実装

**見積もり**: 10-20分、影響範囲が狭い

#### オプション3: `.alert()`での代替（最も簡易）
1. ダウンロードダイアログを`.alert()`で実装
2. フォルダ選択は別途シート表示

**見積もり**: 5-10分、ただしUXが劣る

### 関連ファイル

- [BrowserView.swift](VanishBrowser/VanishBrowser/Views/BrowserView.swift) - ダイアログ表示
- [BrowserViewModel.swift](VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift) - blob: URL処理
- [DownloadDialogView.swift](VanishBrowser/VanishBrowser/Views/DownloadDialogView.swift) - ダイアログUI
- [ZipUtility.swift](VanishBrowser/VanishBrowser/Services/ZipUtility.swift) - ZIP解凍（未実装）

### 参考: Alohaブラウザの動作

1. blob: URLのZIPダウンロードボタンをクリック
2. **文字化けページは表示されない**（ナビゲーションをブロック）
3. ダウンロードダイアログが表示される
4. フォルダを選択してダウンロード
5. ZIPファイルがダウンロード一覧に追加される

**VanishBrowserの現状**: 1-2は実装済み、3が動作しない、4-5は未テスト

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

### 将来の改善案
- [BUG-037](docs/04-improvements/BUG-037-video-swipe-navigation.md) - 動画スワイプナビゲーション（未実装）
- [BUG-038](docs/04-improvements/BUG-038-video-toolbar-tap-bug.md) - 動画ツールバータップバグ（未実装）

---

## ✅ 完了済み（抜粋）

### 最新（2025-11-01）- v1.0.3準備完了
- 自動削除設定画面のUI改善（footer位置、「閉じる」ボタン追加）
- ホーム画面のクイックブックマークをYahoo! JAPANに変更
- ビデオプレーヤーの再生ボタンを中央配置（3カラムレイアウト）
- **動画プレーヤーの閉じるアニメーション改善**（根本解決）
  - 動画ファイルはFileViewerViewを経由せず直接プレーヤーを表示
  - 変な画面が表示される問題を完全に解決
  - アニメーション遅延を削除してスムーズな遷移を実現
- ブックマークのタイトルを1行に省略表示

### 2025-10-27
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
