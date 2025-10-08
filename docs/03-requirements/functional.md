# 機能要件定義

**最終更新**: 2025年10月8日

---

## 📋 MVP機能一覧（Phase 1で実装）

| ID | 機能名 | 優先度 | 実装難易度 | 見積工数 | 説明 |
|----|--------|--------|-----------|---------|------|
| **F1** | ブラウザ機能 | Must | 中 | 15h | WKWebViewベースの基本ブラウジング |
| **F2** | ダウンロード機能 | Must | 高 | 20h | ファイルDL・保存・一覧表示 |
| **F3** | 暗号化ストレージ | Must | 高 | 15h | AES-256によるファイル暗号化 |
| **F4** | 自動削除機能 | Must | 中 | 12h | 90日未起動で全データ削除 |
| **F5** | 削除前通知 | Must | 低 | 5h | 削除7日前のプッシュ通知 |
| **F6** | 生体認証 | Must | 低 | 8h | Face ID/Touch IDによるアプリロック |
| **F7** | タブ管理 | Should | 中 | 10h | 複数タブの開閉・切替 |
| **F8** | ブックマーク | Should | 低 | 8h | URL保存・管理 |
| **F9** | 履歴管理 | Nice to have | 低 | 5h | 閲覧履歴の記録・削除 |
| **F10** | 広告ブロック | Nice to have | 中 | 8h | 基本的な広告ブロック |

**合計見積工数**: 106時間（約3週間）

---

## 🌐 F1: ブラウザ機能

### 概要
WKWebViewを使用した標準的なブラウザ機能を提供。

### 詳細仕様

#### 1.1 URL入力・表示
- **実装内容**:
  - URLバー（テキストフィールド）
  - 検索エンジン統合（デフォルト: DuckDuckGo）
  - https/http自動補完
  - URLエンコーディング対応

- **UI要素**:
  ```
  +---------------------------+
  | [戻る] [進む] [URL欄...] [更新] |
  +---------------------------+
  ```

- **技術詳細**:
  ```swift
  import WebKit

  class BrowserViewController: UIViewController, WKNavigationDelegate {
      private var webView: WKWebView!

      func loadURL(_ urlString: String) {
          guard let url = URL(string: urlString) else { return }
          let request = URLRequest(url: url)
          webView.load(request)
      }
  }
  ```

#### 1.2 ページ表示
- **対応形式**:
  - HTML5
  - JavaScript
  - CSS3
  - 画像（PNG, JPEG, GIF, WebP）
  - 動画（MP4, WebM）※インライン再生

- **WKWebView設定**:
  ```swift
  let config = WKWebViewConfiguration()
  config.allowsInlineMediaPlayback = true
  config.mediaTypesRequiringUserActionForPlayback = []
  ```

#### 1.3 ナビゲーション
- **機能**:
  - 戻る
  - 進む
  - 更新（リロード）
  - 読み込み中止

- **実装**:
  ```swift
  @IBAction func goBack() {
      webView.goBack()
  }

  @IBAction func goForward() {
      webView.goForward()
  }

  @IBAction func reload() {
      webView.reload()
  }
  ```

#### 1.4 プライバシー設定
- **クッキー管理**:
  - セッションクッキーのみ許可
  - サードパーティクッキーブロック
  - アプリ終了時にクッキー削除（オプション）

- **実装**:
  ```swift
  let dataStore = WKWebsiteDataStore.nonPersistent()
  config.websiteDataStore = dataStore
  ```

### ユーザーストーリー
```
As a ユーザー
I want URLを入力してWebページを閲覧したい
So that 情報収集やエンターテイメントを楽しめる
```

### 受け入れ条件
- [x] URLバーにURLを入力してページが表示される
- [x] 戻る・進む・更新ボタンが動作する
- [x] HTTPSページで警告が表示されない
- [x] JavaScript動作が正常

---

## 📥 F2: ダウンロード機能

### 概要
Webページ上のファイルをローカルに暗号化保存。

### 詳細仕様

#### 2.1 ダウンロード対象
- **対応形式**:
  - 画像: PNG, JPEG, GIF, WebP
  - 動画: MP4, MOV, WebM
  - ドキュメント: PDF, TXT, MD
  - 圧縮ファイル: ZIP
  - その他: すべてのMIMEタイプ

#### 2.2 ダウンロード開始
- **トリガー**:
  1. リンク長押し → 「ダウンロード」メニュー
  2. 画像長押し → 「画像を保存」
  3. `<a download>`属性付きリンククリック

- **実装**:
  ```swift
  extension BrowserViewController: WKDownloadDelegate {
      func webView(_ webView: WKWebView,
                   navigationAction: WKNavigationAction,
                   didBecome download: WKDownload) {
          download.delegate = self
      }

      func download(_ download: WKDownload,
                    decideDestinationUsing response: URLResponse,
                    suggestedFilename: String,
                    completionHandler: @escaping (URL?) -> Void) {
          let documentsPath = FileManager.default.urls(
              for: .documentDirectory,
              in: .userDomainMask
          )[0]
          let destinationURL = documentsPath
              .appendingPathComponent("Downloads")
              .appendingPathComponent(suggestedFilename)

          completionHandler(destinationURL)
      }
  }
  ```

#### 2.3 ダウンロード進捗表示
- **UI**:
  ```
  +---------------------------+
  | ダウンロード中...          |
  | [=====>    ] 45% (2.3MB)  |
  | sample_video.mp4          |
  +---------------------------+
  ```

- **実装**:
  ```swift
  func download(_ download: WKDownload,
                didReceiveData bytesWritten: Int64,
                totalBytesWritten: Int64,
                totalBytesExpectedToWrite: Int64) {
      let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
      DispatchQueue.main.async {
          self.progressView.progress = progress
      }
  }
  ```

#### 2.4 ファイル保存場所
- **ディレクトリ構造**:
  ```
  Documents/
  └── Downloads/
      ├── IMG_20251008_001.jpg  (暗号化済み)
      ├── video_sample.mp4       (暗号化済み)
      └── document.pdf           (暗号化済み)
  ```

- **iCloudバックアップ除外**:
  ```swift
  var resourceValues = URLResourceValues()
  resourceValues.isExcludedFromBackup = true
  try fileURL.setResourceValues(resourceValues)
  ```

#### 2.5 ファイル一覧画面
- **UI**:
  ```
  +---------------------------+
  | Downloads                 |
  +---------------------------+
  | 📷 IMG_001.jpg    2.3 MB  |
  | 🎥 video.mp4     15.8 MB  |
  | 📄 document.pdf   1.2 MB  |
  +---------------------------+
  | 合計: 3ファイル (19.3 MB) |
  +---------------------------+
  ```

- **機能**:
  - ファイル名表示
  - サムネイル表示（画像・動画）
  - ファイルサイズ表示
  - ダウンロード日時表示
  - ソート（名前・日時・サイズ）
  - 検索

#### 2.6 ファイル操作
- **アクション**:
  - プレビュー（QuickLook）
  - 削除
  - 共有（他アプリへ送信）
  - 名前変更

### ユーザーストーリー
```
As a ユーザー
I want Webページの動画や画像をダウンロードしたい
So that オフラインでも閲覧できる
```

### 受け入れ条件
- [x] リンク長押しでダウンロード開始
- [x] 進捗が表示される
- [x] ファイル一覧で確認できる
- [x] プレビューが動作する
- [x] ファイルが暗号化されている

---

## 🔐 F3: 暗号化ストレージ

### 概要
ダウンロードしたファイルをAES-256で暗号化して保存。

### 詳細仕様

#### 3.1 暗号化方式
- **アルゴリズム**: AES-256-GCM
- **鍵管理**: Keychain（iOS標準）
- **IV（初期化ベクトル）**: ランダム生成（ファイルごと）

#### 3.2 暗号化処理
- **実装**:
  ```swift
  import CryptoKit

  func encryptFile(at sourceURL: URL, to destinationURL: URL) throws {
      // 1. ファイル読み込み
      let data = try Data(contentsOf: sourceURL)

      // 2. Keychainから鍵取得（なければ生成）
      let key = try getOrCreateEncryptionKey()

      // 3. 暗号化
      let sealedBox = try AES.GCM.seal(data, using: key)

      // 4. 保存（IV + 暗号文 + タグ）
      var encryptedData = Data()
      encryptedData.append(sealedBox.nonce.withUnsafeBytes { Data($0) })
      encryptedData.append(sealedBox.ciphertext)
      encryptedData.append(sealedBox.tag)

      try encryptedData.write(to: destinationURL)
  }

  func getOrCreateEncryptionKey() throws -> SymmetricKey {
      let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: "VanishBrowserEncryptionKey",
          kSecReturnData as String: true
      ]

      var item: CFTypeRef?
      let status = SecItemCopyMatching(query as CFDictionary, &item)

      if status == errSecSuccess, let keyData = item as? Data {
          return SymmetricKey(data: keyData)
      } else {
          // 新規作成
          let key = SymmetricKey(size: .bits256)
          let keyData = key.withUnsafeBytes { Data($0) }

          let addQuery: [String: Any] = [
              kSecClass as String: kSecClassGenericPassword,
              kSecAttrAccount as String: "VanishBrowserEncryptionKey",
              kSecValueData as String: keyData
          ]
          SecItemAdd(addQuery as CFDictionary, nil)

          return key
      }
  }
  ```

#### 3.3 復号処理
- **実装**:
  ```swift
  func decryptFile(at sourceURL: URL) throws -> Data {
      let encryptedData = try Data(contentsOf: sourceURL)
      let key = try getOrCreateEncryptionKey()

      // IV, 暗号文, タグを分離
      let nonceSize = 12
      let tagSize = 16

      let nonce = try AES.GCM.Nonce(
          data: encryptedData.prefix(nonceSize)
      )
      let ciphertext = encryptedData
          .dropFirst(nonceSize)
          .dropLast(tagSize)
      let tag = encryptedData.suffix(tagSize)

      let sealedBox = try AES.GCM.SealedBox(
          nonce: nonce,
          ciphertext: ciphertext,
          tag: tag
      )

      return try AES.GCM.open(sealedBox, using: key)
  }
  ```

#### 3.4 Core Data暗号化
- **設定**:
  ```swift
  let container = NSPersistentContainer(name: "VanishBrowser")
  let description = container.persistentStoreDescriptions.first
  description?.setOption(
      FileProtectionType.complete as NSObject,
      forKey: NSPersistentStoreFileProtectionKey
  )
  ```

### ユーザーストーリー
```
As a セキュリティ意識の高いユーザー
I want ダウンロードしたファイルが暗号化されていることを確認したい
So that 第三者にデータを見られる心配がない
```

### 受け入れ条件
- [x] ファイルがAES-256で暗号化される
- [x] 暗号化鍵がKeychainに保存される
- [x] 復号が正常に動作する
- [x] iCloudバックアップから除外される

---

## 🗑️ F4: 自動削除機能

### 概要
90日間未起動の場合、全データを自動削除。

### 詳細仕様

#### 4.1 最終起動日時の記録
- **保存場所**: UserDefaults
- **実装**:
  ```swift
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      // 最終起動日時を記録
      UserDefaults.standard.set(Date(), forKey: "lastOpenedAt")

      // 削除チェック
      checkAndDeleteIfNeeded()

      return true
  }
  ```

#### 4.2 日数計算ロジック
- **実装**:
  ```swift
  func checkAndDeleteIfNeeded() {
      guard let lastOpened = UserDefaults.standard.object(forKey: "lastOpenedAt") as? Date else {
          return // 初回起動
      }

      let calendar = Calendar.current
      let days = calendar.dateComponents([.day], from: lastOpened, to: Date()).day ?? 0

      if days >= 90 {
          deleteAllData()
      }
  }
  ```

#### 4.3 削除実行
- **削除対象**:
  1. ダウンロードファイル（Documents/Downloads/）
  2. Core Dataの全レコード
  3. UserDefaults（一部を除く）
  4. Cookieストア
  5. キャッシュ

- **実装**:
  ```swift
  func deleteAllData() {
      // 1. ファイル削除
      let fileManager = FileManager.default
      let downloadsURL = fileManager.urls(
          for: .documentDirectory,
          in: .userDomainMask
      )[0].appendingPathComponent("Downloads")

      try? fileManager.removeItem(at: downloadsURL)

      // 2. Core Data削除
      let context = persistentContainer.viewContext
      let fetchRequest: NSFetchRequest<NSFetchRequestResult> = DownloadedFile.fetchRequest()
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
      try? context.execute(deleteRequest)

      // 3. UserDefaults削除
      UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

      // 4. Cookieストア削除
      let dataStore = WKWebsiteDataStore.default()
      dataStore.removeData(
          ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
          modifiedSince: .distantPast,
          completionHandler: {}
      )

      // 5. アプリ終了
      exit(0)
  }
  ```

#### 4.4 削除後の挙動
- **UI表示**:
  ```
  +---------------------------+
  | データが削除されました      |
  |                           |
  | 90日間未起動のため、      |
  | すべてのデータを削除しました |
  |                           |
  | [OK]                      |
  +---------------------------+
  ```

### ユーザーストーリー
```
As a デジタル遺品を気にするユーザー
I want 90日間アプリを起動しなかった場合に自動削除されたい
So that 万が一のときにデータが残らない
```

### 受け入れ条件
- [x] 起動時に最終起動日時が記録される
- [x] 90日経過判定が正確
- [x] 全データが削除される
- [x] 削除後メッセージが表示される

---

## 🔔 F5: 削除前通知

### 概要
削除7日前にプッシュ通知でユーザーに警告。

### 詳細仕様

#### 5.1 通知スケジュール設定
- **タイミング**: 83日目（90日の7日前）
- **実装**:
  ```swift
  import UserNotifications

  func scheduleDeletionWarning() {
      let center = UNUserNotificationCenter.current()

      // 通知許可リクエスト
      center.requestAuthorization(options: [.alert, .sound]) { granted, error in
          guard granted else { return }

          // 83日後の通知をスケジュール
          let content = UNMutableNotificationContent()
          content.title = "Vanish Browser"
          content.body = "7日後にすべてのデータが削除されます。アプリを開いてキャンセルしてください。"
          content.sound = .default

          let trigger = UNTimeIntervalNotificationTrigger(
              timeInterval: 83 * 24 * 60 * 60,  // 83日
              repeats: false
          )

          let request = UNNotificationRequest(
              identifier: "deletionWarning",
              content: content,
              trigger: trigger
          )

          center.add(request)
      }
  }
  ```

#### 5.2 通知文言
- **日本語**:
  ```
  タイトル: Vanish Browser
  本文: 7日後にすべてのデータが削除されます。
       アプリを開いてキャンセルしてください。
  ```

- **英語**:
  ```
  Title: Vanish Browser
  Body: All data will be deleted in 7 days.
        Open the app to cancel.
  ```

#### 5.3 通知キャンセル
- **条件**: アプリを起動した場合
- **実装**:
  ```swift
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      // 通知キャンセル
      UNUserNotificationCenter.current().removePendingNotificationRequests(
          withIdentifiers: ["deletionWarning"]
      )

      // 新しい通知をスケジュール
      scheduleDeletionWarning()

      return true
  }
  ```

### ユーザーストーリー
```
As a ユーザー
I want 削除される前に通知が欲しい
So that 誤って削除されることを防げる
```

### 受け入れ条件
- [x] 83日目に通知が届く
- [x] アプリ起動で通知がキャンセルされる
- [x] 新しい通知が再スケジュールされる

---

## 🔒 F6: 生体認証

### 概要
Face ID / Touch IDによるアプリロック。

### 詳細仕様

#### 6.1 認証タイミング
- アプリ起動時
- バックグラウンドから復帰時（5秒以上経過）

#### 6.2 実装
```swift
import LocalAuthentication

func authenticateUser(completion: @escaping (Bool) -> Void) {
    let context = LAContext()
    var error: NSError?

    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        let reason = "Vanish Browserを開くには認証が必要です"

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, authError in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    } else {
        // 生体認証非対応デバイス → パスコード認証
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { success, authError in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
```

#### 6.3 認証失敗時
- **UI**:
  ```
  +---------------------------+
  | 認証に失敗しました         |
  | [再試行]                   |
  +---------------------------+
  ```

- **リトライ制限**: 5回まで
- **5回失敗後**: アプリ終了

### ユーザーストーリー
```
As a プライバシー重視のユーザー
I want 生体認証でアプリをロックしたい
So that 他人に見られることを防げる
```

### 受け入れ条件
- [x] Face ID/Touch IDで認証できる
- [x] 認証失敗時にリトライできる
- [x] バックグラウンド復帰時も認証される

---

## 📑 F7: タブ管理（Should機能）

### 概要
複数のWebページを同時に開く。

### 詳細仕様
- 最大10タブ
- タブ一覧表示
- タブ切替
- 新規タブ作成
- タブ削除

### 実装優先度
Phase 1でMVPに含める（Should）

---

## ⭐ F8: ブックマーク（Should機能）

### 概要
よく見るページをブックマーク保存。

### 詳細仕様
- URL + タイトル保存
- フォルダ管理
- 編集・削除
- エクスポート（JSON）

### 実装優先度
Phase 1でMVPに含める（Should）

---

## 📊 Phase 2以降の機能

### VPN機能（Phase 3）
- OpenVPN統合
- サーバー選択（5カ国）
- 自動接続

### クラウドバックアップ（Phase 3）
- iCloud暗号化バックアップ
- 端末間同期

### 広告ブロック強化（Phase 2）
- uBlock Origin相当のフィルター
- カスタムフィルター追加

---

## 📋 実装チェックリスト

### Phase 1 MVP
- [ ] F1: ブラウザ機能
  - [ ] URL入力・表示
  - [ ] ページ表示
  - [ ] ナビゲーション
  - [ ] プライバシー設定
- [ ] F2: ダウンロード機能
  - [ ] ダウンロード開始
  - [ ] 進捗表示
  - [ ] ファイル一覧
  - [ ] ファイル操作
- [ ] F3: 暗号化ストレージ
  - [ ] AES-256暗号化
  - [ ] Keychain統合
  - [ ] 復号処理
- [ ] F4: 自動削除機能
  - [ ] 最終起動日記録
  - [ ] 日数計算
  - [ ] 削除実行
- [ ] F5: 削除前通知
  - [ ] 通知スケジュール
  - [ ] 通知キャンセル
- [ ] F6: 生体認証
  - [ ] Face ID/Touch ID
  - [ ] 認証失敗処理
- [ ] F7: タブ管理
- [ ] F8: ブックマーク

---

**次のドキュメント**: [非機能要件 (./non-functional.md)](./non-functional.md)
