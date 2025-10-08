# 非機能要件

**最終更新**: 2025年10月8日

---

## ⚡ パフォーマンス要件

### 1. アプリ起動時間

| 指標 | 目標値 | 測定方法 |
|------|--------|---------|
| **コールドスタート** | 2秒以内 | アプリアイコンタップから初回画面表示まで |
| **ウォームスタート** | 1秒以内 | バックグラウンドから復帰 |
| **生体認証時間** | 1秒以内 | Face ID/Touch ID認証完了まで |

**実装方針**:
```swift
// 遅延ロード - 必要な機能だけ初期化
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 最小限の初期化
    setupCoreComponents()  // 0.5秒以内

    // 非同期で重い処理
    DispatchQueue.global().async {
        self.setupNonCriticalComponents()
    }

    return true
}
```

---

### 2. ブラウザ表示速度

| 指標 | 目標値 | 基準 |
|------|--------|------|
| **ページ読み込み** | Safari同等 | WKWebView使用のため自動達成 |
| **スクロール** | 60 FPS | フレームドロップなし |
| **JavaScript実行** | Safari同等 | WKWebView標準性能 |

**測定方法**:
- Instruments（Time Profiler）
- FPS表示デバッグモード

---

### 3. メモリ使用量

| シナリオ | 目標値 | 許容上限 |
|---------|--------|---------|
| **アイドル状態** | 50 MB以下 | 80 MB |
| **ブラウジング中** | 100 MB以下 | 150 MB |
| **動画再生中** | 150 MB以下 | 200 MB |
| **ダウンロード中** | 100 MB以下 | 150 MB |

**メモリリーク対策**:
```swift
// WKWebView のメモリリーク防止
deinit {
    webView.stopLoading()
    webView.configuration.userContentController.removeAllUserScripts()
    webView = nil
}
```

**監視方法**:
- Instruments（Leaks, Allocations）
- 本番環境でのクラッシュレポート分析

---

### 4. ストレージ効率

| 項目 | 目標値 |
|------|--------|
| **アプリサイズ** | 10 MB以下 |
| **Core Dataサイズ** | 1 MB以下（1000ブックマーク想定） |
| **キャッシュサイズ** | 50 MB上限 |

**実装**:
```swift
// キャッシュサイズ制限
let cache = URLCache(
    memoryCapacity: 10 * 1024 * 1024,   // 10 MB
    diskCapacity: 50 * 1024 * 1024,      // 50 MB
    diskPath: "VanishBrowserCache"
)
URLCache.shared = cache
```

---

### 5. ネットワーク効率

| 指標 | 目標値 |
|------|--------|
| **タイムアウト** | 30秒 |
| **リトライ回数** | 3回 |
| **同時接続数** | 6接続（HTTP/1.1標準） |

---

## 🔒 セキュリティ要件

### 1. データ暗号化

| 対象 | 暗号化方式 | 鍵管理 |
|------|-----------|--------|
| **ダウンロードファイル** | AES-256-GCM | Keychain |
| **Core Data** | NSFileProtection.complete | iOS標準 |
| **通信** | TLS 1.3 | WKWebView標準 |

**実装詳細**:
```swift
// ファイル暗号化（CryptoKit使用）
import CryptoKit

let key = SymmetricKey(size: .bits256)  // Keychainから取得
let sealedBox = try AES.GCM.seal(fileData, using: key)

// Core Data暗号化
let description = container.persistentStoreDescriptions.first
description?.setOption(
    FileProtectionType.complete as NSObject,
    forKey: NSPersistentStoreFileProtectionKey
)
```

**セキュリティ監査**:
- Phase 2でサードパーティ監査実施予定

---

### 2. 認証・認可

| 機能 | 要件 |
|------|------|
| **生体認証** | Face ID/Touch ID必須 |
| **パスコード** | 生体認証非対応時のフォールバック |
| **認証失敗** | 5回でアプリロック |

**実装**:
```swift
// 認証失敗カウント
var failedAttempts = 0
let maxAttempts = 5

func handleAuthFailure() {
    failedAttempts += 1
    if failedAttempts >= maxAttempts {
        // アプリ終了
        exit(0)
    }
}
```

---

### 3. iCloudバックアップ除外

**要件**: ダウンロードファイルは絶対にiCloudにバックアップしない

**実装**:
```swift
func excludeFromBackup(url: URL) throws {
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true
    try url.setResourceValues(resourceValues)
}
```

**検証方法**:
```swift
// バックアップ除外の確認
let resourceValues = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
assert(resourceValues.isExcludedFromBackup == true)
```

---

### 4. トラッキング防止

| 対象 | 対策 |
|------|------|
| **Cookie** | サードパーティブロック |
| **User-Agent** | 標準Safari User-Agent使用 |
| **Referer** | オリジン送信のみ |
| **アクセス解析** | 一切使用しない |

**実装**:
```swift
// Cookieブロック
let config = WKWebViewConfiguration()
config.websiteDataStore = WKWebsiteDataStore.nonPersistent()

// User-Agentはデフォルト（Safari同等）
```

---

## 🛡️ プライバシー要件

### 1. データ収集ポリシー

**収集するデータ**: **なし**

| データ種別 | 収集 | 外部送信 | 理由 |
|-----------|------|---------|------|
| 閲覧履歴 | ローカルのみ | ❌ | プライバシー重視 |
| ダウンロード履歴 | ローカルのみ | ❌ | プライバシー重視 |
| 検索キーワード | 保存しない | ❌ | プライバシー重視 |
| 位置情報 | 収集しない | ❌ | 不要 |
| 連絡先 | 収集しない | ❌ | 不要 |
| 写真 | 収集しない | ❌ | 不要（DLのみ） |
| クラッシュログ | 収集しない | ❌ | Phase 2で検討 |

**App Privacy Nutrition Label**:
```
データ収集: なし
トラッキング: なし
データリンク: なし
```

---

### 2. ローカル完結

**要件**: すべての処理をデバイス内で完結

**禁止事項**:
- ❌ 外部サーバーへのデータ送信
- ❌ アクセス解析ツール（Google Analytics等）
- ❌ クラッシュレポートツール（Crashlytics等）※Phase 2で検討
- ❌ 広告SDK

**ネットワーク通信**:
- ✅ Webページ表示のみ許可
- ✅ ファイルダウンロードのみ許可

---

### 3. App Tracking Transparency (ATT)

**対応**: 不要（トラッキングしないため）

**Info.plist設定**:
```xml
<!-- ATT不要の明示 -->
<key>NSUserTrackingUsageDescription</key>
<string>このアプリはトラッキングを行いません</string>
```

---

## 📱 互換性要件

### 1. iOS バージョン

| 項目 | 要件 |
|------|------|
| **最小対応バージョン** | iOS 15.0 |
| **推奨バージョン** | iOS 17.0以上 |
| **テスト対象** | iOS 15.0, 16.0, 17.0 |

**理由**:
- iOS 15.0: WKDownload API対応
- iOS 17.0: 最新セキュリティ機能

---

### 2. デバイス対応

| デバイス | 対応 | 最適化 |
|---------|------|--------|
| **iPhone** | ✅ | メイン対応 |
| **iPad** | ✅ | Phase 2で最適化 |
| **iPod touch** | ✅ | テスト対象外 |

**画面サイズ対応**:
- iPhone SE (4.7インチ) 〜 iPhone 15 Pro Max (6.7インチ)
- iPad (9.7インチ) 〜 iPad Pro (12.9インチ)

---

### 3. ダークモード対応

**要件**: システム設定に従う

**実装**:
```swift
// SwiftUIの場合、自動対応
// カスタムカラーは両モード対応色を定義

Color("PrimaryBackground")  // Assets.xcassetsで両モード定義
```

**確認項目**:
- [x] ライトモード表示
- [x] ダークモード表示
- [x] 自動切替

---

## 🔧 保守性要件

### 1. コード品質

| 指標 | 目標値 | 測定方法 |
|------|--------|---------|
| **コメント率** | 30%以上 | SwiftLintカスタムルール |
| **関数の複雑度** | 10以下 | SwiftLint `cyclomatic_complexity` |
| **ファイル行数** | 400行以下 | SwiftLint `file_length` |
| **関数行数** | 50行以下 | SwiftLint `function_body_length` |

**SwiftLint設定** (.swiftlint.yml):
```yaml
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - empty_count
  - explicit_init
line_length: 120
function_body_length: 50
file_length: 400
cyclomatic_complexity: 10
```

---

### 2. テストカバレッジ

| レイヤー | 目標カバレッジ | 実装優先度 |
|---------|---------------|-----------|
| **Model** | 80%以上 | High |
| **ViewModel** | 70%以上 | High |
| **View** | 50%以上 | Medium |
| **Service** | 80%以上 | High |

**Phase 1目標**: 全体60%以上

**実装方針**:
```swift
// XCTestでユニットテスト
class AutoDeleteServiceTests: XCTestCase {
    func testShouldDeleteAfter90Days() {
        let service = AutoDeleteService()
        let lastOpened = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        XCTAssertTrue(service.shouldDelete(lastOpened: lastOpened))
    }
}
```

---

### 3. ドキュメント

**必須ドキュメント**:
- [x] README.md
- [x] API仕様（コード内コメント）
- [ ] アーキテクチャ図（architecture.md）
- [ ] データモデル図（data-model.md）

**コードコメントルール**:
```swift
/// ファイルを暗号化して保存
/// - Parameters:
///   - sourceURL: 暗号化するファイルのURL
///   - destinationURL: 保存先URL
/// - Throws: 暗号化エラー、ファイルI/Oエラー
func encryptFile(at sourceURL: URL, to destinationURL: URL) throws {
    // 実装
}
```

---

## 📊 スケーラビリティ要件

### 1. データ容量

| 項目 | 目標値 | 上限値 |
|------|--------|--------|
| **ダウンロードファイル数** | 1,000ファイル | 10,000ファイル |
| **ストレージ使用量** | 1 GB | 10 GB |
| **ブックマーク数** | 100件 | 1,000件 |
| **タブ数** | 10タブ | 20タブ |

**上限超過時の挙動**:
```swift
// ファイル数上限チェック
func canDownloadMore() -> Bool {
    let fileCount = getDownloadedFileCount()
    if fileCount >= 10000 {
        showAlert("ファイル数が上限に達しました")
        return false
    }
    return true
}
```

---

### 2. 同時処理

| 処理 | 同時実行数 |
|------|-----------|
| **ダウンロード** | 3ファイル |
| **暗号化** | 1ファイル |
| **タブ読み込み** | 制限なし（WKWebView制御） |

**実装**:
```swift
let downloadQueue = OperationQueue()
downloadQueue.maxConcurrentOperationCount = 3
```

---

## 🌍 ローカライゼーション

### 1. 対応言語

**Phase 1**:
- 日本語（メイン）
- 英語

**Phase 2以降**:
- 中国語（簡体字）
- 韓国語

### 2. 文字列管理

**実装**:
```swift
// Localizable.strings使用
Text("browser.url_placeholder")  // SwiftUI
NSLocalizedString("browser.url_placeholder", comment: "")  // UIKit
```

**Localizable.strings (ja)**:
```
"browser.url_placeholder" = "URLまたは検索ワードを入力";
"delete.warning" = "7日後にすべてのデータが削除されます";
```

**Localizable.strings (en)**:
```
"browser.url_placeholder" = "Enter URL or search term";
"delete.warning" = "All data will be deleted in 7 days";
```

---

## ♿ アクセシビリティ要件

### 1. VoiceOver対応

**要件**: すべてのUI要素にアクセシビリティラベル

**実装**:
```swift
Button(action: reload) {
    Image(systemName: "arrow.clockwise")
}
.accessibilityLabel("ページを再読み込み")

TextField("URL", text: $urlString)
    .accessibilityLabel("URLバー")
    .accessibilityHint("URLまたは検索ワードを入力してください")
```

**確認項目**:
- [x] すべてのボタンにラベル
- [x] テキストフィールドにヒント
- [x] 画像にalt相当のラベル

---

### 2. Dynamic Type対応

**要件**: システムフォントサイズに追従

**実装**:
```swift
Text("タイトル")
    .font(.headline)  // システムフォント使用
    .dynamicTypeSize(.medium ... .xxxLarge)  // サイズ範囲指定
```

---

### 3. カラーコントラスト

**要件**: WCAG 2.1 AA準拠（コントラスト比4.5:1以上）

**確認ツール**:
- Xcode Accessibility Inspector
- Color Contrast Analyzer

---

## 🚀 デプロイ要件

### 1. App Store審査対応

**遵守ガイドライン**:
- App Store Review Guidelines 2.1（アプリ完全性）
- 4.0（デザイン）
- 5.1.1（プライバシー - データ収集）

**リジェクト回避策**:
- ✅ クラッシュゼロ
- ✅ プライバシーポリシー明記
- ✅ スクリーンショットに実機画像使用
- ✅ デモアカウント不要（認証なし）

---

### 2. TestFlight配布

**Phase 1目標**:
- ベータテスター: 50人
- テスト期間: 2週間
- フィードバック: 30件以上

---

### 3. バージョニング

**ルール**: Semantic Versioning (semver)

```
v1.0.0 - Phase 1 MVP
v1.1.0 - バグ修正・小機能追加
v2.0.0 - Phase 2 有料化
v3.0.0 - Phase 3 VPN追加
```

---

## 📋 非機能要件チェックリスト

### パフォーマンス
- [ ] アプリ起動2秒以内
- [ ] メモリ使用量150MB以内
- [ ] ページ表示速度Safari同等

### セキュリティ
- [ ] AES-256暗号化実装
- [ ] Keychain統合
- [ ] iCloudバックアップ除外
- [ ] 生体認証実装

### プライバシー
- [ ] データ外部送信ゼロ
- [ ] トラッキングゼロ
- [ ] プライバシーポリシー作成

### 互換性
- [ ] iOS 15.0以上対応
- [ ] iPhone/iPad対応
- [ ] ダークモード対応

### 保守性
- [ ] SwiftLint導入
- [ ] コメント率30%
- [ ] ユニットテスト実装

### アクセシビリティ
- [ ] VoiceOver対応
- [ ] Dynamic Type対応
- [ ] カラーコントラスト確認

---

**次のドキュメント**: [アーキテクチャ設計 (../04-design/architecture.md)](../04-design/architecture.md)
