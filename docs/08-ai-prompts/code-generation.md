# AIコード生成プロンプト集

**最終更新**: 2025年10月8日

---

## 📚 はじめに

このドキュメントは、Cursor/Claude等のAIコーディングツールで使用するプロンプトテンプレート集です。

**使い方**:
1. 以下のプロンプトをコピー
2. `[...]`内を実際の値に置き換え
3. Cursor/Claudeに貼り付け
4. 生成されたコードを確認・調整

---

## 🎨 SwiftUIビュー生成

### プロンプトテンプレート

```
以下の要件でSwiftUIビューを作成してください:

【画面名】
[画面名]（例: ブラウザ画面、ファイル一覧画面）

【主要UI要素】
- [UI要素1]（例: URLバー）
- [UI要素2]（例: WebView）
- [UI要素3]（例: ツールバー）

【レイアウト】
[レイアウト説明]（例: 上部にナビゲーションバー、中央にWebView、下部にタブバー）

【参考ドキュメント】
- docs/04-design/ui-flow.md
- docs/04-design/architecture.md

【技術要件】
- SwiftUI使用
- MVVMパターン
- @StateObject / @Published使用
- Appleヒューマンインターフェースガイドライン準拠
```

### 使用例

```
以下の要件でSwiftUIビューを作成してください:

【画面名】
ブラウザ画面

【主要UI要素】
- URLバー（TextField）
- 戻る・進むボタン
- WebView表示領域
- 下部タブバー（ブラウザ・ダウンロード・設定）

【レイアウト】
上部にナビゲーションバー（戻る・進む・URLバー）、
中央にWebView、
下部にタブバー

【参考ドキュメント】
- docs/04-design/ui-flow.md

【技術要件】
- SwiftUI使用
- BrowserViewModelとバインディング
- WKWebViewをUIViewRepresentableでラップ
```

---

## 🧠 ViewModel生成

### プロンプトテンプレート

```
以下の要件でViewModelを作成してください:

【ViewModel名】
[名前]ViewModel（例: BrowserViewModel）

【責務】
[ViewModelの責務]（例: WKWebViewの管理、URL読み込み）

【プロパティ】
- @Published var [プロパティ名]: [型]
- @Published var [プロパティ名]: [型]

【メソッド】
- func [メソッド名]() - [説明]
- func [メソッド名]() - [説明]

【依存サービス】
- [サービス名]（例: BrowserEngine）

【参考ドキュメント】
- docs/04-design/architecture.md

【技術要件】
- @MainActor使用
- ObservableObjectプロトコル準拠
- Combineでリアクティブプログラミング
```

### 使用例

```
以下の要件でViewModelを作成してください:

【ViewModel名】
BrowserViewModel

【責務】
WKWebViewの管理、URL読み込み、ナビゲーション操作

【プロパティ】
- @Published var urlString: String
- @Published var canGoBack: Bool
- @Published var canGoForward: Bool
- @Published var isLoading: Bool

【メソッド】
- func loadURL() - URLバーの文字列からページ読み込み
- func goBack() - 前のページへ
- func goForward() - 次のページへ
- func reload() - ページ再読み込み

【依存サービス】
- BrowserEngine（WKWebView管理）

【参考ドキュメント】
- docs/04-design/architecture.md
- docs/03-requirements/functional.md

【技術要件】
- @MainActor使用
- webView.publisher(for: \.canGoBack)でCombine監視
```

---

## 🗄️ Core Dataエンティティ生成

### プロンプトテンプレート

```
以下の要件でCore Dataエンティティを作成してください:

【エンティティ名】
[エンティティ名]（例: DownloadedFile）

【属性】
- [属性名]: [型] - [説明]
- [属性名]: [型] - [説明]

【メソッド】
- var [計算プロパティ名]: [型] - [説明]

【参考ドキュメント】
- docs/04-design/data-model.md

【技術要件】
- NSManagedObjectサブクラス
- Identifiableプロトコル準拠（SwiftUI List用）
- @NSManaged使用
```

### 使用例

```
以下の要件でCore Dataエンティティを作成してください:

【エンティティ名】
DownloadedFile

【属性】
- id: UUID - 一意識別子
- fileName: String - ファイル名
- filePath: String - 相対パス
- downloadedAt: Date - ダウンロード日時
- fileSize: Int64 - ファイルサイズ（バイト）
- mimeType: String? - MIMEタイプ（任意）

【メソッド】
- var formattedFileSize: String - 人間が読める形式（例: "15.8 MB"）
- var fileTypeIcon: String - SF Symbolsアイコン名

【参考ドキュメント】
- docs/04-design/data-model.md

【技術要件】
- ByteCountFormatterでサイズ変換
- mimeTypeからアイコン推測
```

---

## 🔐 暗号化サービス生成

### プロンプトテンプレート

```
以下の要件で暗号化サービスを実装してください:

【機能】
ファイルをAES-256-GCMで暗号化・復号

【メソッド】
- func encrypt(_ data: Data) throws -> Data
- func decrypt(_ encryptedData: Data) throws -> Data
- func getOrCreateKey() throws -> SymmetricKey

【仕様】
- CryptoKit使用
- 鍵はKeychainに保存
- Nonce（12byte）+ Ciphertext + Tag（16byte）の構造

【参考ドキュメント】
- docs/03-requirements/functional.md（F3: 暗号化ストレージ）
- docs/04-design/data-model.md

【技術要件】
- import CryptoKit
- import Security（Keychain用）
- エラーハンドリング
```

---

## 🗑️ 自動削除ロジック生成

### プロンプトテンプレート

```
以下の仕様で自動削除サービスを実装してください:

【クラス名】
AutoDeleteService

【メソッド】
- func checkAndDeleteIfNeeded() - 起動時チェック
- func shouldDelete(lastOpened: Date) -> Bool - 削除判定
- func deleteAllData() - 全データ削除
- func scheduleDeletionWarning() - 通知スケジュール

【仕様】
- 90日間未起動で削除
- UserDefaultsで最終起動日記録
- 削除7日前に通知
- 削除対象: ファイル、Core Data、UserDefaults、Cookie

【参考ドキュメント】
- docs/03-requirements/functional.md（F4: 自動削除機能）
- docs/04-design/architecture.md

【技術要件】
- Calendar.current.dateComponentsで日数計算
- FileManager.default.removeItemでファイル削除
- NSBatchDeleteRequestでCore Data削除
- UNUserNotificationCenterで通知
```

---

## 📥 ダウンロード機能生成

### プロンプトテンプレート

```
以下の仕様でダウンロード機能を実装してください:

【機能】
WKWebViewでファイルダウンロード

【実装内容】
- WKDownloadDelegateの実装
- 進捗表示
- ファイル保存（暗号化）
- Core Dataに記録

【メソッド】
- func download(from url: URL)
- func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, ...)
- func downloadDidFinish(_ download: WKDownload)

【参考ドキュメント】
- docs/03-requirements/functional.md（F2: ダウンロード機能）
- docs/04-design/architecture.md

【技術要件】
- WKWebView iOS 14.5+のWKDownload API使用
- StorageManager.encrypt()で暗号化
- Core DataのDownloadedFileに保存
- @Published var progressで進捗通知
```

---

## 🧪 ユニットテスト生成

### プロンプトテンプレート

```
以下のクラスのユニットテストを作成してください:

【テスト対象】
[クラス名]（例: AutoDeleteService）

【テストケース】
1. [テストケース名] - [期待結果]
2. [テストケース名] - [期待結果]
3. [テストケース名] - [期待結果]

【参考ドキュメント】
- docs/06-testing/test-plan.md

【技術要件】
- XCTest使用
- setUp/tearDownで初期化・後処理
- XCTAssertTrue/XCTAssertEqual等でアサーション
- @testableでインポート
```

### 使用例

```
以下のクラスのユニットテストを作成してください:

【テスト対象】
AutoDeleteService

【テストケース】
1. testShouldDeleteAfter90Days - 90日経過後はtrueを返す
2. testShouldNotDeleteBefore90Days - 90日未満はfalseを返す
3. testLastOpenedDateUpdate - 起動時に最終起動日が更新される

【参考ドキュメント】
- docs/06-testing/test-plan.md

【技術要件】
- Calendar.current.date(byAdding:)で日付操作
- UserDefaultsのモック不要（実際のUserDefaults使用）
- XCTAssertTrue/XCTAssertFalseでブール値確認
```

---

## 🔍 デバッグ・リファクタリング

### バグ修正プロンプト

```
以下のコードにバグがあります。修正してください:

【コード】
```swift
[バグのあるコード]
```

【問題】
[バグの説明]（例: メモリリークが発生する）

【期待動作】
[正しい動作]

【参考ドキュメント】
- docs/04-design/architecture.md
```

---

### リファクタリングプロンプト

```
以下のコードをリファクタリングしてください:

【コード】
```swift
[リファクタリング対象コード]
```

【改善点】
- [改善1]（例: 関数が長すぎる → 分割）
- [改善2]（例: 重複コードがある → 共通化）

【制約】
- SwiftLint準拠
- 関数は50行以内
- コメント率30%以上

【参考ドキュメント】
- docs/05-development/tech-stack.md
```

---

## 📄 ドキュメント生成

### コメント生成プロンプト

```
以下の関数に適切なドキュメントコメントを追加してください:

【コード】
```swift
[コメントなしコード]
```

【要件】
- /// 形式のドキュメントコメント
- Parameters、Returns、Throws等を明記
- 日本語で記述

【例】
```swift
/// ファイルを暗号化して保存
/// - Parameters:
///   - data: 暗号化するデータ
///   - fileName: 保存ファイル名
/// - Returns: 保存先URL
/// - Throws: 暗号化エラー、ファイルI/Oエラー
func saveEncryptedFile(_ data: Data, fileName: String) throws -> URL
```
```

---

## 🎯 実践例

### 例1: ブラウザ画面の実装

**プロンプト**:
```
以下の要件でSwiftUIビューを作成してください:

【画面名】
ブラウザ画面

【主要UI要素】
- 上部: 戻る・進むボタン、URLバー、メニューボタン
- 中央: WKWebView表示領域
- 下部: タブバー（ブラウザ・ダウンロード・設定）

【レイアウト】
VStackで縦配置。
ナビゲーションバーは.padding()付き、
WebViewはexpanding、
タブバーは固定高さ。

【参考ドキュメント】
- docs/04-design/ui-flow.md（S01: ブラウザ画面）
- docs/04-design/architecture.md

【技術要件】
- BrowserViewModelを@StateObjectで保持
- URLバーは@Bindingで双方向バインディング
- WKWebViewはUIViewRepresentableでラップ
- ダークモード対応
```

**期待される出力**:
完全に動作するBrowserView.swiftのコード

---

### 例2: 自動削除サービスのテスト

**プロンプト**:
```
以下のクラスのユニットテストを作成してください:

【テスト対象】
AutoDeleteService

【テストケース】
1. testShouldDeleteAfter90Days - 90日経過後はshouldDelete()がtrueを返す
2. testShouldNotDeleteBefore90Days - 89日経過後はshouldDelete()がfalseを返す
3. testExactly90Days - ちょうど90日後はtrueを返す
4. test1Day - 1日後はfalseを返す

【参考ドキュメント】
- docs/06-testing/test-plan.md（TC001）
- docs/04-design/architecture.md

【技術要件】
- XCTest使用
- Calendar.current.date(byAdding: .day, value: -90, to: Date())で日付生成
- XCTAssertTrue/XCTAssertFalseで判定
```

**期待される出力**:
AutoDeleteServiceTests.swiftのコード

---

## 💡 プロンプト作成のコツ

### ✅ Good（良い例）

```
【明確な要件】
DownloadedFileエンティティを作成。
属性: id, fileName, filePath, downloadedAt, fileSize。
formattedFileSizeメソッドでByteCountFormatter使用。

【参考ドキュメント明記】
docs/04-design/data-model.md参照。

【技術的制約】
NSManagedObject、@NSManaged使用。
```

### ❌ Bad（悪い例）

```
ファイルのやつ作って
```

**理由**:
- 要件が曖昧
- 参考情報なし
- 技術的詳細不明

---

## 📚 参考ドキュメント一覧

| ドキュメント | 用途 |
|-------------|------|
| [architecture.md](../04-design/architecture.md) | MVVMパターン、レイヤー構成 |
| [data-model.md](../04-design/data-model.md) | Core Dataエンティティ定義 |
| [ui-flow.md](../04-design/ui-flow.md) | 画面レイアウト、UI要素 |
| [functional.md](../03-requirements/functional.md) | 機能仕様 |
| [non-functional.md](../03-requirements/non-functional.md) | パフォーマンス・セキュリティ要件 |
| [tech-stack.md](../05-development/tech-stack.md) | 使用技術、ライブラリ |
| [test-plan.md](../06-testing/test-plan.md) | テスト戦略、テストケース |

---

## 🚀 実践ワークフロー

### 新機能実装の流れ

1. **要件確認**: docs/03-requirements/functional.mdを読む
2. **設計確認**: docs/04-design/architecture.mdでレイヤー確認
3. **プロンプト作成**: 上記テンプレートを使用
4. **コード生成**: Cursor/Claudeで生成
5. **コードレビュー**: 生成されたコードを確認
6. **テスト作成**: テスト生成プロンプト使用
7. **実装**: Xcodeで動作確認

---

## 📋 プロンプトチェックリスト

新しいプロンプトを作る際は、以下を確認：

- [ ] 要件が明確か？
- [ ] 参考ドキュメントを指定したか？
- [ ] 技術的制約を明記したか？
- [ ] 期待される出力形式を説明したか？
- [ ] 例を示したか（必要に応じて）？

---

**このプロンプト集を使って、効率的にVanish Browserを開発しましょう！**
