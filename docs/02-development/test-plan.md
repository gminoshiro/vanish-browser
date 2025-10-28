# テスト計画

**最終更新**: 2025年10月8日

---

## 🎯 テスト戦略

### テストピラミッド

```
        /\
       /  \      E2Eテスト（UIテスト）
      /----\     10%
     /      \
    /--------\   統合テスト
   /          \  20%
  /------------\
 /--------------\ ユニットテスト
/________________\ 70%
```

**Phase 1目標**:
- ユニットテスト: 60%カバレッジ
- UIテスト: 主要フロー3本
- 手動テスト: 全機能

---

## 🧪 テストスコープ

### 1. ユニットテスト（優先度: 高）

**対象**:
- ViewModel層
- Service層
- Utility層

**ツール**: XCTest

---

### 2. 統合テスト（優先度: 中）

**対象**:
- Core Data CRUD
- ファイル暗号化・復号
- WKWebView連携

**ツール**: XCTest

---

### 3. UIテスト（優先度: 中）

**対象**:
- 主要ユーザーフロー
- 画面遷移
- エラーハンドリング

**ツール**: XCTest UI Testing

---

### 4. 手動テスト（優先度: 必須）

**対象**:
- UX確認
- 実機動作確認
- パフォーマンス確認

---

## 📝 テストケース

### TC001: 90日後に自動削除されるか

**優先度**: 🔴 Critical

**前提条件**:
- アプリが初回起動済み
- 最終起動日が90日以前に設定されている

**テスト手順**:
1. `UserDefaults`で最終起動日を90日前に設定
2. アプリを起動
3. `AutoDeleteService.checkAndDeleteIfNeeded()`が呼ばれる

**期待結果**:
- すべてのファイルが削除される
- Core Dataが空になる
- アプリが終了する

**実装**:
```swift
class AutoDeleteServiceTests: XCTestCase {
    var service: AutoDeleteService!

    override func setUp() {
        service = AutoDeleteService()
    }

    func testShouldDeleteAfter90Days() {
        // 90日前の日付を設定
        let lastOpened = Calendar.current.date(
            byAdding: .day,
            value: -90,
            to: Date()
        )!

        // 削除判定
        let shouldDelete = service.shouldDelete(lastOpened: lastOpened)

        XCTAssertTrue(shouldDelete, "90日経過後は削除すべき")
    }

    func testShouldNotDeleteBefore90Days() {
        // 89日前の日付
        let lastOpened = Calendar.current.date(
            byAdding: .day,
            value: -89,
            to: Date()
        )!

        let shouldDelete = service.shouldDelete(lastOpened: lastOpened)

        XCTAssertFalse(shouldDelete, "90日未満は削除しない")
    }
}
```

---

### TC002: 通知が7日前に届くか

**優先度**: 🔴 Critical

**前提条件**:
- 通知許可が有効
- アプリが起動済み

**テスト手順**:
1. アプリ起動時に通知スケジュール
2. 83日後に通知がトリガーされる

**期待結果**:
- 83日後に通知が表示される
- 通知内容が正しい

**実装**:
```swift
class NotificationServiceTests: XCTestCase {
    func testNotificationScheduling() {
        let center = UNUserNotificationCenter.current()

        // 通知スケジュール
        let service = NotificationService()
        service.scheduleDeletionWarning()

        // 登録確認
        let expectation = expectation(description: "Notification scheduled")

        center.getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 1)
            XCTAssertEqual(requests.first?.identifier, "deletionWarning")

            // トリガー確認
            if let trigger = requests.first?.trigger as? UNTimeIntervalNotificationTrigger {
                let expectedInterval = 83 * 24 * 60 * 60  // 83日
                XCTAssertEqual(trigger.timeInterval, TimeInterval(expectedInterval), accuracy: 1.0)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
```

---

### TC003: 暗号化が正しく動作するか

**優先度**: 🔴 Critical

**前提条件**:
- ファイルがダウンロードされている

**テスト手順**:
1. テストデータを用意
2. `StorageManager.encrypt()`で暗号化
3. `StorageManager.decrypt()`で復号
4. 元データと一致確認

**期待結果**:
- 暗号化・復号が成功
- 復号後のデータが元データと完全一致

**実装**:
```swift
class StorageManagerTests: XCTestCase {
    var storageManager: StorageManager!
    var testData: Data!

    override func setUp() {
        storageManager = StorageManager.shared
        testData = "Hello, Vanish Browser!".data(using: .utf8)!
    }

    func testEncryptionDecryption() throws {
        // 暗号化
        let encrypted = try storageManager.encrypt(testData)

        // 暗号化されていることを確認
        XCTAssertNotEqual(encrypted, testData)

        // 復号
        let decrypted = try storageManager.decrypt(encrypted)

        // 復号後のデータが元データと一致
        XCTAssertEqual(decrypted, testData)
    }

    func testEncryptedDataStructure() throws {
        let encrypted = try storageManager.encrypt(testData)

        // データ構造確認（Nonce 12byte + Ciphertext + Tag 16byte）
        XCTAssertGreaterThan(encrypted.count, 28)  // 最小サイズ
    }
}
```

---

### TC004: ファイルダウンロードが正常に動作するか

**優先度**: 🟡 High

**前提条件**:
- インターネット接続あり

**テスト手順**:
1. テスト用URLからファイルダウンロード
2. 進捗が更新される
3. ダウンロード完了通知

**期待結果**:
- ファイルが保存される
- Core Dataに記録される
- 暗号化されている

**実装**:
```swift
class DownloadManagerTests: XCTestCase {
    var downloadManager: DownloadManager!

    override func setUp() {
        downloadManager = DownloadManager.shared
    }

    func testDownload() {
        let expectation = expectation(description: "Download completed")

        let testURL = URL(string: "https://via.placeholder.com/150")!

        downloadManager.download(from: testURL) { result in
            switch result {
            case .success(let fileURL):
                // ファイルが存在するか確認
                XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

                // 暗号化されているか確認
                let data = try? Data(contentsOf: fileURL)
                XCTAssertNotNil(data)

                expectation.fulfill()

            case .failure(let error):
                XCTFail("Download failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 30.0)
    }
}
```

---

### TC005: 生体認証が動作するか

**優先度**: 🟡 High

**前提条件**:
- Face ID/Touch ID対応デバイス

**テスト手順**:
1. アプリ起動
2. 生体認証ダイアログ表示
3. 認証成功

**期待結果**:
- アプリが開く

**手動テスト**: 実機で確認必須

---

### TC006: ブックマーク追加・削除

**優先度**: 🟢 Medium

**実装**:
```swift
class BookmarkViewModelTests: XCTestCase {
    var viewModel: BookmarkViewModel!

    override func setUp() {
        viewModel = BookmarkViewModel()
    }

    func testAddBookmark() {
        let title = "GitHub"
        let url = "https://github.com"

        viewModel.addBookmark(title: title, url: url)

        XCTAssertEqual(viewModel.bookmarks.count, 1)
        XCTAssertEqual(viewModel.bookmarks.first?.title, title)
        XCTAssertEqual(viewModel.bookmarks.first?.url, url)
    }

    func testDeleteBookmark() {
        // 追加
        viewModel.addBookmark(title: "Test", url: "https://example.com")

        // 削除
        let bookmark = viewModel.bookmarks.first!
        viewModel.deleteBookmark(bookmark)

        XCTAssertEqual(viewModel.bookmarks.count, 0)
    }
}
```

---

## 🖥️ UIテスト

### UIT001: URL入力 → ページ表示

```swift
class BrowserUITests: XCTestCase {
    func testURLInput() {
        let app = XCUIApplication()
        app.launch()

        // URL入力
        let urlField = app.textFields["URLバー"]
        XCTAssertTrue(urlField.exists)

        urlField.tap()
        urlField.typeText("https://example.com\n")

        // WebView表示確認
        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 10))
    }
}
```

---

### UIT002: ファイル一覧表示

```swift
func testDownloadListDisplay() {
    let app = XCUIApplication()
    app.launch()

    // ダウンロードタブをタップ
    app.tabBars.buttons["ダウンロード"].tap()

    // リスト表示確認
    let table = app.tables.firstMatch
    XCTAssertTrue(table.exists)
}
```

---

### UIT003: 設定画面表示

```swift
func testSettingsDisplay() {
    let app = XCUIApplication()
    app.launch()

    // 設定タブをタップ
    app.tabBars.buttons["設定"].tap()

    // トグル確認
    let authToggle = app.switches["生体認証"]
    XCTAssertTrue(authToggle.exists)
}
```

---

## 📊 テスト環境

### シミュレータ

| デバイス | iOS | 優先度 |
|---------|-----|--------|
| iPhone SE (3rd) | 15.0 | High |
| iPhone 15 | 17.0 | High |
| iPhone 15 Pro Max | 17.0 | Medium |
| iPad (10th) | 17.0 | Low |

---

### 実機

| デバイス | iOS | 優先度 |
|---------|-----|--------|
| 開発者のiPhone | 最新 | High |

---

## 🚀 リリース前チェックリスト

### 機能テスト
- [ ] ブラウジング動作確認
- [ ] ファイルダウンロード確認
- [ ] 暗号化・復号確認
- [ ] 自動削除ロジック確認
- [ ] 通知確認
- [ ] 生体認証確認
- [ ] タブ管理確認
- [ ] ブックマーク確認

### 非機能テスト
- [ ] 起動時間（2秒以内）
- [ ] メモリ使用量（150MB以内）
- [ ] クラッシュなし
- [ ] メモリリークなし
- [ ] バッテリー消費確認

### UI/UX
- [ ] ライトモード表示確認
- [ ] ダークモード表示確認
- [ ] Dynamic Type確認
- [ ] VoiceOver確認
- [ ] 小画面（iPhone SE）確認
- [ ] 大画面（Pro Max）確認

### セキュリティ
- [ ] ファイルが暗号化されている
- [ ] iCloudバックアップから除外
- [ ] Keychain保存確認
- [ ] 通信が全てHTTPS

### App Store対応
- [ ] プライバシーポリシー確認
- [ ] スクリーンショット準備
- [ ] App Store説明文確認
- [ ] バージョン番号確認

---

## 🧪 ベータテスト計画（TestFlight）

### 目標

| 項目 | 目標値 |
|------|--------|
| **ベータテスター数** | 50人 |
| **テスト期間** | 2週間 |
| **フィードバック数** | 30件以上 |
| **クラッシュ率** | 0.1%以下 |

---

### 募集方法

1. **Twitter/Reddit投稿**
2. **ProductHunt掲載**
3. **知人・友人に依頼**

---

### フィードバック項目

```
【必須】
- 使いやすさ（5段階評価）
- バグ報告
- 要望機能

【任意】
- 価格についての意見（¥300は妥当か？）
- 競合ブラウザとの比較
```

---

### 配信手順

1. Xcode: **Product** → **Archive**
2. **Distribute App** → **TestFlight**
3. TestFlight Connectで招待リンク生成
4. ベータテスターに共有

---

## 📋 テストカバレッジ目標

| レイヤー | Phase 1目標 | Phase 2目標 |
|---------|------------|------------|
| **Model** | 60% | 80% |
| **ViewModel** | 60% | 70% |
| **Service** | 70% | 80% |
| **全体** | 60% | 75% |

---

## 🔍 パフォーマンステスト

### Instrumentsによる測定

**測定項目**:
- Time Profiler（CPU使用率）
- Allocations（メモリ使用量）
- Leaks（メモリリーク）
- Energy Log（バッテリー消費）

**手順**:
1. Xcode: **Product** → **Profile**
2. Instrumentsテンプレート選択
3. 録画開始
4. アプリ操作
5. 結果分析

---

## 📚 参考資料

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [TestFlight Guide](https://developer.apple.com/testflight/)
- [Instruments User Guide](https://help.apple.com/instruments/)

---

**次のドキュメント**: [App Store掲載情報 (../07-launch/app-store-listing.md)](../07-launch/app-store-listing.md)
