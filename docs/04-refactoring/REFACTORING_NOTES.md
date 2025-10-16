# リファクタリング・改善提案

## 完了した項目

### テストコード作成
- ✅ AutoDeleteServiceTests.swift - 自動削除サービスのテスト
- ✅ DownloadManagerTests.swift - ダウンロードマネージャーのテスト
- ✅ HLSParserTests.swift - HLS品質パーサーのテスト
- ✅ 不要なサンプルテストの削除

### コード品質
- ✅ TODOコメントなし（検索結果: 0件）
- ✅ FIXMEコメントなし（検索結果: 0件）

---

## 今後の改善提案

### 1. ログ管理システムの導入

現在、`print()`が多用されているが、本番環境では不要なログが多い。

**推奨事項:**
```swift
enum LogLevel {
    case debug, info, warning, error
}

class Logger {
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isDebugMode else { return }
        print("🔍 [\(file.components(separatedBy: "/").last ?? file):\(line)] \(message)")
    }

    static func info(_ message: String) {
        print("ℹ️ \(message)")
    }

    static func warning(_ message: String) {
        print("⚠️ \(message)")
    }

    static func error(_ message: String, error: Error? = nil) {
        print("❌ \(message)")
        if let error = error {
            print("   Error: \(error.localizedDescription)")
        }
    }
}
```

---

### 2. 長いメソッドの分割

**対象候補:**
- BrowserView.swift: 600行以上 → 複数のファイルに分割
- DownloadManager.swift: 複雑なダウンロードロジック

**分割案:**
```
BrowserView.swift →
  - BrowserView.swift (メインUI)
  - BrowserView+Notifications.swift (通知ハンドリング)
  - BrowserView+Downloads.swift (ダウンロード処理)
  - BrowserView+Navigation.swift (ナビゲーション処理)
```

---

### 3. Magic Number の定数化

**例:**
```swift
// Before
try? await Task.sleep(nanoseconds: 100_000_000)

// After
private enum Constants {
    static let progressUpdateInterval: UInt64 = 100_000_000 // 0.1秒
}
try? await Task.sleep(nanoseconds: Constants.progressUpdateInterval)
```

---

### 4. エラーハンドリングの統一

現在、エラー処理が統一されていない箇所がある。

**推奨事項:**
```swift
enum AppError: LocalizedError {
    case downloadFailed(reason: String)
    case hlsParsingFailed
    case fileNotFound
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .downloadFailed(let reason):
            return "ダウンロードに失敗しました: \(reason)"
        case .hlsParsingFailed:
            return "HLS動画の解析に失敗しました"
        case .fileNotFound:
            return "ファイルが見つかりません"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        }
    }
}
```

---

### 5. 重複コードの削減

**候補:**
- ファイルパス生成ロジック（複数箇所で重複）
- MIME type判定ロジック

**改善案:**
```swift
extension FileManager {
    func downloadsDirectory() -> URL {
        let documentsPath = urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("Downloads")
    }

    func createDownloadPath(fileName: String, folder: String?) throws -> URL {
        let downloadsPath = folder.map { downloadsDirectory().appendingPathComponent($0) }
                            ?? downloadsDirectory()
        try createDirectory(at: downloadsPath, withIntermediateDirectories: true)
        return downloadsPath.appendingPathComponent(fileName)
    }
}
```

---

### 6. 非推奨APIの置き換え

**検出された非推奨API:**
- `AVAssetExportSession.export()` (iOS 18.0で非推奨)
- `AVPlayerItem.status` (iOS 18.0で非推奨)
- `AVAssetExportSession.error` (iOS 18.0で非推奨)

**対応:**
- iOS 18以降は新しいasync/await APIを使用
- デプロイターゲットに応じて条件分岐

---

### 7. テストカバレッジの向上

**未テスト領域:**
- HLSDownloader.downloadHLSAsMP4()
- BookmarkService
- BrowsingHistoryService
- AutoDeleteService.performAutoDelete() (実際の削除処理)

---

### 8. 定数の中央管理

**提案:**
```swift
enum AppConstants {
    enum AutoDelete {
        static let lastActiveDateKey = "lastActiveDate"
        static let checkInterval: TimeInterval = 300 // 5分
    }

    enum Download {
        static let maxConcurrentDownloads = 3
        static let timeout: TimeInterval = 60
    }

    enum FileSize {
        static let megabyte: Int64 = 1_048_576
        static let gigabyte: Int64 = 1_073_741_824
    }
}
```

---

## 優先度

1. **高**: ログ管理システム（本番リリース前に必要）
2. **中**: 長いメソッドの分割、Magic Numberの定数化
3. **低**: エラーハンドリングの統一、重複コードの削減

---

## 実施タイミング

- リリース前: 優先度「高」
- 次回スプリント: 優先度「中」
- バックログ: 優先度「低」
