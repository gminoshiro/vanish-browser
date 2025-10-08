# 技術スタック詳細

**最終更新**: 2025年10月8日

---

## 🛠️ 開発言語・フレームワーク

### Swift 5.9+

**選定理由**:
- iOS開発の標準言語
- モダンな言語機能（async/await、Actor等）
- 型安全性が高い
- パフォーマンスが優れている

**使用する主要機能**:
```swift
// async/await（非同期処理）
func downloadFile(from url: URL) async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

// @MainActor（メインスレッド保証）
@MainActor
class BrowserViewModel: ObservableObject {
    @Published var urlString: String = ""
}

// Property Wrapper
@Published var isLoading: Bool = false
```

**バージョン管理**:
- 最小: Swift 5.9
- 推奨: Swift 6.0（Phase 2以降）

---

### SwiftUI

**選定理由**:
- 宣言的UI（コード量削減）
- Live Previewで開発速度向上
- Appleの推奨フレームワーク
- Combineとの統合性

**主要コンポーネント**:
```swift
// List（一覧表示）
List(files) { file in
    DownloadItemView(file: file)
}

// NavigationView（画面遷移）
NavigationView {
    ContentView()
}

// @State, @StateObject（状態管理）
@State private var urlString: String = ""
@StateObject private var viewModel = BrowserViewModel()

// @Binding（双方向バインディング）
struct ChildView: View {
    @Binding var text: String
}
```

**UIKit統合**:
```swift
// WKWebViewをSwiftUIで使用
struct WebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
```

---

### Combine

**選定理由**:
- Apple標準フレームワーク
- SwiftUIとの親和性
- メモリ管理が自動（ARC）

**使用例**:
```swift
import Combine

class BrowserViewModel: ObservableObject {
    @Published var canGoBack: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        // WKWebViewのプロパティを監視
        webView.publisher(for: \.canGoBack)
            .assign(to: &$canGoBack)
    }
}
```

**代替案**: RxSwift → 採用しない（依存追加を避ける）

---

## 📚 標準ライブラリ

### 1. WKWebView（WebKit）

**用途**: Webブラウジング機能

**主要機能**:
```swift
import WebKit

let config = WKWebViewConfiguration()
config.websiteDataStore = .nonPersistent()  // プライバシー重視
config.allowsInlineMediaPlayback = true

let webView = WKWebView(frame: .zero, configuration: config)
```

**WKNavigationDelegate**:
```swift
extension BrowserEngine: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 didStartProvisionalNavigation navigation: WKNavigation!) {
        print("読み込み開始")
    }

    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        print("読み込み完了")
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        print("エラー: \(error)")
    }
}
```

**WKDownloadDelegate（iOS 14.5+）**:
```swift
extension DownloadManager: WKDownloadDelegate {
    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        let url = downloadsDirectory.appendingPathComponent(suggestedFilename)
        completionHandler(url)
    }

    func downloadDidFinish(_ download: WKDownload) {
        print("ダウンロード完了")
    }
}
```

---

### 2. Core Data

**用途**: ローカルデータベース

**設定**:
```swift
import CoreData

lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "VanishBrowser")

    // 暗号化設定
    let description = container.persistentStoreDescriptions.first
    description?.setOption(
        FileProtectionType.complete as NSObject,
        forKey: NSPersistentStoreFileProtectionKey
    )

    container.loadPersistentStores { _, error in
        if let error = error {
            fatalError("Core Data error: \(error)")
        }
    }

    return container
}()
```

**CRUD操作**:
```swift
// Create
let file = DownloadedFile(context: context)
file.id = UUID()
file.fileName = "sample.jpg"

// Read
let request: NSFetchRequest<DownloadedFile> = DownloadedFile.fetchRequest()
let files = try context.fetch(request)

// Update
file.fileName = "renamed.jpg"
try context.save()

// Delete
context.delete(file)
try context.save()
```

---

### 3. LocalAuthentication

**用途**: 生体認証（Face ID/Touch ID）

**実装**:
```swift
import LocalAuthentication

func authenticateUser(completion: @escaping (Bool) -> Void) {
    let context = LAContext()
    var error: NSError?

    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 error: &error) {
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Vanish Browserを開くには認証が必要です"
        ) { success, authError in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    } else {
        // フォールバック: パスコード認証
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "認証してください"
        ) { success, authError in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
```

**Info.plist設定**:
```xml
<key>NSFaceIDUsageDescription</key>
<string>アプリを開くためにFace IDを使用します</string>
```

---

### 4. UserNotifications

**用途**: プッシュ通知（削除前警告）

**実装**:
```swift
import UserNotifications

func scheduleDeletionWarning() {
    let center = UNUserNotificationCenter.current()

    // 許可リクエスト
    center.requestAuthorization(options: [.alert, .sound]) { granted, error in
        guard granted else { return }

        // 通知内容
        let content = UNMutableNotificationContent()
        content.title = "Vanish Browser"
        content.body = "7日後にすべてのデータが削除されます"
        content.sound = .default

        // トリガー（83日後）
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 83 * 24 * 60 * 60,
            repeats: false
        )

        // リクエスト
        let request = UNNotificationRequest(
            identifier: "deletionWarning",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }
}
```

---

### 5. CryptoKit

**用途**: ファイル暗号化（AES-256）

**実装**:
```swift
import CryptoKit

func encrypt(_ data: Data, key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.seal(data, using: key)

    var encrypted = Data()
    encrypted.append(sealedBox.nonce.withUnsafeBytes { Data($0) })
    encrypted.append(sealedBox.ciphertext)
    encrypted.append(sealedBox.tag)

    return encrypted
}

func decrypt(_ encrypted: Data, key: SymmetricKey) throws -> Data {
    let nonceSize = 12
    let tagSize = 16

    let nonce = try AES.GCM.Nonce(data: encrypted.prefix(nonceSize))
    let ciphertext = encrypted.dropFirst(nonceSize).dropLast(tagSize)
    let tag = encrypted.suffix(tagSize)

    let sealedBox = try AES.GCM.SealedBox(
        nonce: nonce,
        ciphertext: ciphertext,
        tag: tag
    )

    return try AES.GCM.open(sealedBox, using: key)
}
```

---

### 6. Security（Keychain）

**用途**: 暗号化鍵の安全な保存

**実装**:
```swift
import Security

func saveToKeychain(_ data: Data, account: String) -> Bool {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecValueData as String: data
    ]

    SecItemDelete(query as CFDictionary)  // 既存削除
    let status = SecItemAdd(query as CFDictionary, nil)

    return status == errSecSuccess
}

func loadFromKeychain(account: String) -> Data? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecReturnData as String: true
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    guard status == errSecSuccess else { return nil }
    return item as? Data
}
```

---

## 🚫 サードパーティライブラリ

**基本方針**: サードパーティライブラリは使用しない

**理由**:
1. ✅ **App Store審査通過率向上**
2. ✅ **依存関係の削減**
3. ✅ **セキュリティリスク低減**
4. ✅ **メンテナンスコスト削減**
5. ✅ **バイナリサイズ削減**

**標準APIで十分カバー可能**:

| 機能 | サードパーティ候補 | 標準API |
|------|------------------|---------|
| ブラウザ | - | WKWebView |
| DB | Realm | Core Data |
| 暗号化 | - | CryptoKit |
| 認証 | - | LocalAuthentication |
| 通知 | - | UserNotifications |
| ネットワーク | Alamofire | URLSession |
| 画像読み込み | Kingfisher | URLSession + Image |

**Phase 3でのみ検討**:
- OpenVPN（VPN機能追加時）

---

## 🔧 開発ツール

### Xcode 15+

**必須バージョン**: 15.0以上

**使用機能**:
- SwiftUI Preview
- Instruments（パフォーマンス測定）
- Accessibility Inspector
- Memory Graph Debugger

**推奨設定**:
```
Build Settings:
- Swift Language Version: Swift 5.9
- iOS Deployment Target: 15.0
- Enable Bitcode: No（廃止済み）
```

---

### Cursor / Claude

**用途**: AIペアプログラミング

**使用場面**:
- コード生成
- リファクタリング
- バグ修正
- ドキュメント作成

**プロンプト例**:
```
以下の要件でSwiftUIビューを作成:
- 画面名: ダウンロードリスト
- 主要UI要素: List、SearchBar、ファイルアイコン
参考: docs/04-design/ui-flow.md
```

---

### Git / GitHub

**バージョン管理戦略**:

```
main           ← 本番リリース版
  ↑
develop        ← 開発統合ブランチ
  ↑
feature/xxx    ← 機能開発ブランチ
```

**コミットメッセージ規約**:
```
feat: 新機能追加
fix: バグ修正
docs: ドキュメント更新
refactor: リファクタリング
test: テスト追加
chore: ビルド設定等

例:
feat: ダウンロード進捗表示機能を追加
fix: 暗号化処理のメモリリーク修正
```

---

## 🧪 テストフレームワーク

### XCTest（標準）

**用途**: ユニットテスト、UIテスト

**ユニットテスト例**:
```swift
import XCTest
@testable import VanishBrowser

class AutoDeleteServiceTests: XCTestCase {
    var service: AutoDeleteService!

    override func setUp() {
        service = AutoDeleteService()
    }

    func testShouldDeleteAfter90Days() {
        let lastOpened = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        XCTAssertTrue(service.shouldDelete(lastOpened: lastOpened))
    }

    func testShouldNotDeleteBefore90Days() {
        let lastOpened = Date().addingTimeInterval(-89 * 24 * 60 * 60)
        XCTAssertFalse(service.shouldDelete(lastOpened: lastOpened))
    }
}
```

**UIテスト例**:
```swift
class BrowserUITests: XCTestCase {
    func testURLInput() {
        let app = XCUIApplication()
        app.launch()

        let urlField = app.textFields["URLバー"]
        urlField.tap()
        urlField.typeText("https://example.com\n")

        XCTAssertTrue(app.webViews.firstMatch.exists)
    }
}
```

---

### SwiftUI Preview

**用途**: リアルタイムUI確認

**実装例**:
```swift
struct BrowserView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // ライトモード
            BrowserView()
                .preferredColorScheme(.light)

            // ダークモード
            BrowserView()
                .preferredColorScheme(.dark)

            // 小さい画面
            BrowserView()
                .previewDevice("iPhone SE (3rd generation)")

            // 大きい画面
            BrowserView()
                .previewDevice("iPhone 15 Pro Max")
        }
    }
}
```

---

## 🚀 CI/CD（Phase 2以降）

### GitHub Actions（検討中）

**自動化したい項目**:
- ビルドチェック
- ユニットテスト実行
- SwiftLint実行
- TestFlight配信

**.github/workflows/ci.yml**:
```yaml
name: CI

on:
  push:
    branches: [ develop, main ]
  pull_request:
    branches: [ develop ]

jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Build
      run: xcodebuild -scheme VanishBrowser -sdk iphonesimulator

    - name: Test
      run: xcodebuild test -scheme VanishBrowser -sdk iphonesimulator
```

---

### Fastlane（検討中）

**自動化したい項目**:
- スクリーンショット生成
- App Store提出
- TestFlight配信

**Fastfile**:
```ruby
lane :test do
  run_tests(scheme: "VanishBrowser")
end

lane :beta do
  build_app(scheme: "VanishBrowser")
  upload_to_testflight
end

lane :release do
  build_app(scheme: "VanishBrowser")
  upload_to_app_store
end
```

---

## 📊 技術選定マトリクス

| 技術 | 採用 | 理由 |
|------|------|------|
| **Swift 5.9+** | ✅ | iOS標準、型安全 |
| **SwiftUI** | ✅ | 宣言的UI、開発速度 |
| **Combine** | ✅ | Apple標準、SwiftUI親和性 |
| **WKWebView** | ✅ | 標準ブラウザエンジン |
| **Core Data** | ✅ | 標準DB、暗号化対応 |
| **CryptoKit** | ✅ | 標準暗号化ライブラリ |
| **LocalAuthentication** | ✅ | 標準生体認証 |
| **UserNotifications** | ✅ | 標準通知 |
| **Alamofire** | ❌ | URLSessionで十分 |
| **Realm** | ❌ | Core Dataで十分 |
| **RxSwift** | ❌ | Combineで十分 |
| **Kingfisher** | ❌ | URLSessionで十分 |

---

## 📋 技術スタックチェックリスト

### Phase 1（MVP）
- [x] Swift 5.9+
- [x] SwiftUI
- [x] Combine
- [x] WKWebView
- [x] Core Data
- [x] LocalAuthentication
- [x] CryptoKit
- [x] UserNotifications
- [x] Xcode 15+
- [x] Git/GitHub

### Phase 2以降
- [ ] GitHub Actions（CI）
- [ ] Fastlane（CD）
- [ ] SwiftLint（コード品質）
- [ ] OpenVPN（VPN機能）

---

**次のドキュメント**: [環境構築手順 (./setup.md)](./setup.md)
