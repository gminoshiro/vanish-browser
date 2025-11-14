# FEATURE-011: 検証結果と方向性変更の意思決定

**作成日**: 2025-11-12
**ステータス**: 🔄 **方向性変更 - DL機能強化へ**

---

## 📋 目次

1. [これまでの検証結果（正確な記録）](#これまでの検証結果正確な記録)
2. [方向性変更の意思決定](#方向性変更の意思決定)
3. [技術的制約と懸念事項](#技術的制約と懸念事項)
4. [新しいアプローチ：DL機能強化](#新しいアプローチdl機能強化)
5. [避けるべきこと](#避けるべきこと)

---

## これまでの検証結果（正確な記録）

### ❌ **検証結果の訂正**

**以前の誤った記載**:
```
前回セッションでは動画再生自体は成功していた
```

**正しい検証結果**:
```
❌ 動画再生は一度も成功していない
✅ カスタムプレーヤーが起動しただけ
❌ プレーヤー内はエラーやバグまみれ
❌ 何も成していない
```

**ユーザーフィードバック**:
> "成功はしていない、再生でカスタムプレーやが開いただけでその中身はエラーやバグまみれでなにも成していない"

---

### 検証1: querySelector方式（git stash@{0}）

**実装内容**:
- `WKWebViewFullscreenPlayerView.swift` を作成
- `document.querySelectorAll('video')` でvideo要素を検出
- Cookie転送試行（HTTPCookieStorage.shared使用）

**検証結果**:
```
❌ 失敗 - iframe内動画にアクセスできない

原因:
- 9animeの動画は iframe 内に配置
- cross-origin 制限により document.querySelector では iframe内DOMにアクセス不可
- forMainFrameOnly: false でも iframe内の要素は操作不可

結論: このアプローチは根本的に不可能
```

**stash理由**: 間違ったアプローチのため保存

---

### 検証2: 包括的実装（git stash@{1}）

**実装規模**: 1,450行追加、467行削除

**実装内容**:
1. **NetworkInterceptorScript** (VideoURLSchemeHandler.swift)
   - XHR/fetch フック
   - HTMLMediaElement.src フック
   - MutationObserver でDOM監視
   - iframe内でも動作 (forMainFrameOnly: false)

2. **全画面イベント監視** (BrowserViewModel.swift)
   ```javascript
   video.addEventListener('webkitbeginfullscreen', function(e) {
       e.preventDefault();  // ネイティブ全画面をブロック
       // カスタムプレーヤー起動
   });
   ```

3. **UIWindow監視** (BrowserView.swift)
   - AVPlayerViewController検出
   - ネイティブプレーヤーをインターセプト

4. **Cookie転送試行** (CustomVideoPlayerView.swift)
   ```swift
   // HTTPCookieStorage.shared を使用
   let cookies = HTTPCookieStorage.shared.cookies(for: url)
   ```

**検証結果**:
```
✅ 動画URL検出 - 成功
✅ 全画面イベント取得 - 成功
✅ カスタムプレーヤー起動 - 成功
❌ 動画再生 - 失敗（Cloudflareブロック）

エラー:
- AVPlayer: "動画の再生に失敗しました"
- ブラウザ: Cloudflare "Sorry, you have been blocked"
```

**失敗の原因**:
```
問題: HTTPCookieStorage.shared に WKWebView の Cookie は含まれない

詳細:
- WKWebView は WKWebsiteDataStore で Cookie を管理
- HTTPCookieStorage.shared は Safari/URLSession用
- 両者は完全に独立したストレージ
- そのため Cookie が AVPlayer に転送されない
```

**stash理由**: Cookie転送が不完全で再生できなかったため

---

### 検証3: Private API試行（ログから推測）

**試行したPrivate API**:
```swift
// WKUIDelegate Private Methods
_willEnterFullScreenWithCallback
_webViewWillEnterFullScreen
_webViewDidEnterFullScreen

// WKWebView Private Properties
_frames  // iframe内動画URL取得用
```

**検証結果**:
```
✅ iframe内動画URL取得 - 成功
🔓🔓🔓 [Private API] iframe内動画URL取得成功: https://...

❌ 動画再生 - 失敗（Cloudflareブロック）

結論: URL取得できても再生はできない
```

**失敗の原因**:
```
問題: AVPlayer の HTTP リクエストに Cookie/認証情報が含まれない

詳細:
- Private API で iframe内URLを取得できた
- しかし AVPlayer は独立したHTTPクライアント
- WKWebView のセッション/Cookie を継承しない
- Cloudflareが「不正なリクエスト」と判定してブロック
```

**stash理由**:
- App Store審査リスク（Private API使用）
- Cloudflare問題を解決できなかった

---

### 🔍 根本原因の特定

**全ての試行で共通する問題**:
```
AVPlayer は WKWebView のセッション/Cookie を継承できない

[技術的詳細]
WKWebView Session:
  - Cookie: WKWebsiteDataStore.httpCookieStore
  - 認証状態: Cloudflare チャレンジをパス済み
  - User-Agent: Safari互換

AVPlayer Session:
  - Cookie: 空（または HTTPCookieStorage.shared の内容）
  - 認証状態: なし
  - User-Agent: AVPlayer独自のUA

結果: Cloudflare が「新しい未認証セッション」と判定 → ブロック
```

**結論**:
```
❌ どの方法でも AVPlayer でのストリーミング再生は不可能

理由:
1. Cookie転送方法を変えても、AVPlayerは独立したHTTPクライアント
2. Private APIを使っても、HTTPリクエストレベルで分離されている
3. Cloudflareは「WKWebViewのセッション ≠ AVPlayerのセッション」を検知
```

---

## 方向性変更の意思決定

### 🎯 新しい目標

**変更前（実現不可能）**:
```
9animeでネイティブの再生ボタンをタップ
→ Aloha Browser風のカスタム全画面プレーヤーで再生
```

**変更後（実現可能）**:
```
9animeなどCloudflare保護サイトからの動画ダウンロード機能強化

1. WKWebViewのセッションを使った動画ダウンロード
2. 再生中動画の長押しダウンロード
3. 既存のダウンロード機能は完全に保持
```

---

### 🤔 意思決定の理由

#### 1. 技術的実現可能性

**カスタムプレーヤー再生（AVPlayer使用）**:
```
実現可能性: ❌ 不可能

理由:
- AVPlayerは独立したHTTPクライアント
- WKWebViewのセッション/Cookieを継承不可
- Private APIを使っても同じ（HTTPレイヤーで分離）
- Cloudflare保護を回避する方法なし（違法な方法以外）
```

**ダウンロード（URLSession使用）**:
```
実現可能性: ✅ 可能

理由:
- URLSessionはWKWebViewのCookieを利用可能
  WKWebsiteDataStore.default().httpCookieStore.getAllCookies()
- ダウンロードは1回のHTTPリクエスト（ストリーミングより簡単）
- User-Agent/Refererヘッダーを付与可能
- 技術的に実績あり（既存ダウンロード機能が動作中）
```

#### 2. 競合分析（Aloha Browser）

**ユーザー指摘**:
> "Aloha Browserは無料でこのDL機能を有しています"

**訂正された事実**:
```
Aloha Browser:
- ダウンロード機能: 無料
- カスタムプレーヤー: 無料
- VPN: ¥500/月（有料）

Vanish Browser（現状）:
- ダウンロード機能: ✅ あり（通常サイト）
- カスタムプレーヤー: ❌ なし
- Cloudflare保護サイトDL: ❌ なし
```

**差別化戦略**:
```
目標: Alohaと同等のDL機能を提供

実装:
1. Cloudflare保護サイトからのDL（優先度：高）
2. 長押しDL機能（優先度：中）
3. フローティングDLボタン（優先度：低）

価格優位性:
- Vanish: ¥300買い切り
- Aloha: 基本無料だが、VPN等は ¥500/月

ポジショニング:
「Aloha並みのDL機能 + デジタル遺品対策」
```

#### 3. ユーザー疲労への配慮

**ユーザーフィードバック**:
> "もう疲れた"
> "本当に直る？直る気がしない"

**これまでの問題**:
```
1. 動作しない機能の開発を繰り返した
2. 「成功した」という誤った報告
3. 根本原因の理解不足
4. 意味のない時間の浪費
```

**方向性変更の効果**:
```
✅ 実現可能な機能に注力
✅ 短期間で成果を出せる
✅ 既存機能を壊さない
✅ ユーザーに価値を提供できる
```

#### 4. 開発効率

**カスタムプレーヤー開発**:
```
推定工数: 不明（実現不可能）
成功確率: 0%
リスク: App Store審査（Private API使用）
```

**ダウンロード機能強化**:
```
推定工数: 3-5日
成功確率: 90%以上（既存実装の拡張）
リスク: なし（標準APIのみ使用）
```

---

### 📊 意思決定マトリクス

| 評価項目 | カスタムプレーヤー | ダウンロード強化 |
|---------|------------------|----------------|
| **技術的実現可能性** | ❌ 不可能 | ✅ 可能 |
| **開発工数** | ∞（実現不可） | 3-5日 |
| **成功確率** | 0% | 90%+ |
| **App Store審査** | ❌ 危険 | ✅ 安全 |
| **ユーザー価値** | 高（実現すれば） | 高 |
| **既存機能への影響** | 不明 | なし |
| **競合優位性** | Alohaと同等 | Alohaと同等 |

**結論**: ダウンロード機能強化が最適

---

## 技術的制約と懸念事項

### 🚨 絶対に不可能なこと

#### 1. AVPlayerでのCloudflare保護動画再生
```
理由:
- AVPlayerは独立したHTTPクライアント
- WKWebViewのセッション/Cookieを継承しない仕様
- Appleの設計上の制約（変更不可能）
- Private APIを使っても同じ
```

#### 2. iframe内動画のquerySelectorアクセス
```
理由:
- Same-Origin Policy（Web標準のセキュリティ制約）
- iframe内DOMへの直接アクセスは禁止
- forMainFrameOnly: false でも操作不可
```

### ⚠️ 懸念事項（ダウンロード機能）

#### 懸念1: HLS (.m3u8) のダウンロード
```
問題:
- HLS は複数の .ts ファイルに分割されている
- .m3u8 ファイルはプレイリスト（動画ファイルではない）
- 単純にダウンロードしても再生不可

解決策（2つのアプローチ）:

【アプローチA】HLS動画は対象外
- 簡単で確実
- ただし9animeは対象外になる可能性

【アプローチB】HLS対応ダウンロード（複雑）
- .m3u8をパース
- 全.tsファイルをダウンロード
- 1つのMP4に結合
- 工数: 5-10日
- FFmpegライブラリが必要
```

**推奨**: まずアプローチAで実装し、必要ならアプローチBを追加

#### 懸念2: Cloudflareのレート制限
```
問題:
- 大量のダウンロードリクエスト → レート制限
- Cookie/セッションが無効化される可能性

対策:
- ダウンロード間隔の制御
- リトライロジック（429エラー時）
- ユーザーへの警告表示
```

#### 懸念3: 既存ダウンロード機能への影響
```
懸念:
- 新しい実装で既存機能が壊れる可能性

対策:
- 既存コードは一切変更しない
- 新しいダウンロードロジックは別関数
- 条件分岐で使い分け:
  if isCloudflareProtectedSite {
      // 新しいWKWebViewセッション使用ダウンロード
  } else {
      // 既存のダウンロード処理
  }
```

#### 懸念4: DRM保護コンテンツ
```
問題:
- FairPlay DRM等で保護されたコンテンツはダウンロード不可
- 9animeは通常DRMなし（HLSのみ）

対応:
- DRMコンテンツはエラー表示
- 「この動画は保護されているためダウンロードできません」
```

---

## 新しいアプローチ：DL機能強化

### 🎯 実装する機能

#### Phase 1: WKWebViewセッションDL（最優先）
```
目的: Cloudflare保護サイトからのダウンロード

実装:
1. WKWebsiteDataStore.httpCookieStore.getAllCookies() でCookie取得
2. URLRequestにCookie/User-Agent/Refererを付与
3. URLSession.shared.downloadTask() でダウンロード
4. 既存のダウンロード保存処理を再利用

実装場所:
- DownloadManager.swift に新しい関数追加
  func downloadWithWKWebViewSession(url: URL, cookies: [HTTPCookie])

推定工数: 1-2日
```

**コード例**:
```swift
func downloadWithWKWebViewSession(url: URL, referrer: String) {
    WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
        // ドメイン一致するCookieのみフィルタ
        let relevantCookies = cookies.filter {
            url.host?.contains($0.domain) ?? false
        }

        // Cookie文字列生成
        let cookieString = relevantCookies
            .map { "\($0.name)=\($0.value)" }
            .joined(separator: "; ")

        // リクエスト作成
        var request = URLRequest(url: url)
        request.setValue(cookieString, forHTTPHeaderField: "Cookie")
        request.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(referrer, forHTTPHeaderField: "Referer")

        // ダウンロード開始
        let task = URLSession.shared.downloadTask(with: request) {
            location, response, error in
            // 既存の保存処理を呼び出し
            self.saveDownloadedFile(from: location, ...)
        }
        task.resume()
    }
}
```

#### Phase 2: 長押しダウンロード（中優先）
```
目的: 再生中動画を長押しでダウンロード

実装:
1. WKWebView に LongPressGestureRecognizer 追加
2. タップ位置のDOM要素を取得
   document.elementFromPoint(x, y)
3. <video> 要素なら src を抽出
4. Phase 1のダウンロード関数を呼び出し

実装場所:
- BrowserView.swift に GestureRecognizer 追加
- JavaScript: detectVideoAtPoint(x, y)

推定工数: 1-2日
```

#### Phase 3: UIエンハンス（低優先）
```
目的: ダウンロードUIの改善

実装例:
- フローティングダウンロードボタン
- ダウンロード進捗表示の改善
- ダウンロード履歴

推定工数: 2-3日
```

---

### ✅ 守るべきこと

#### 1. 既存ダウンロード機能の保持
```
絶対条件:
- 既存のダウンロード機能は1ピクセルも壊さない
- 新しいロジックは完全に追加のみ
- 既存コードの変更は最小限
```

**実装パターン**:
```swift
func download(url: URL, context: DownloadContext) {
    if context.isCloudflareProtected {
        // 新しいWKWebViewセッションダウンロード
        downloadWithWKWebViewSession(url: url, referrer: context.referrer)
    } else {
        // 既存のダウンロード処理（変更なし）
        existingDownloadMethod(url: url)
    }
}
```

#### 2. エラーハンドリング
```
必須:
- DRMコンテンツ: 「保護されているためダウンロードできません」
- レート制限: 「しばらく待ってから再試行してください」
- ネットワークエラー: リトライ or 中断
- 容量不足: 「ストレージ容量が不足しています」
```

#### 3. ユーザー体験
```
要件:
- ダウンロード中のプログレス表示
- キャンセル可能
- バックグラウンドダウンロード対応
- ダウンロード完了通知
```

---

## 避けるべきこと

### ❌ 絶対に避けるべき

#### 1. Private API の使用
```
理由:
- App Store審査でリジェクトされる
- iOS更新で動作しなくなる可能性
- そもそもCloudflare問題を解決できない（検証済み）

結論: 標準APIのみ使用
```

#### 2. AVPlayerでのストリーミング再生（Cloudflare保護サイト）
```
理由:
- 技術的に不可能（検証済み）
- 時間の無駄

結論: この方向は完全に諦める
```

#### 3. 既存機能の大規模リファクタリング
```
理由:
- 動作中のコードを壊すリスク
- 「意味のない時間」の浪費

結論: 追加のみ、既存コードは触らない
```

#### 4. 複雑な実装の一気通貫
```
理由:
- デバッグが困難
- 問題の切り分けができない

結論: 段階的に実装・テスト
  ステップ1: Cookie取得のログ確認
  ステップ2: HTTPリクエスト送信
  ステップ3: ダウンロード成功確認
  ステップ4: 保存処理
```

---

### ⚠️ 慎重に扱うべき

#### 1. HLS (.m3u8) のダウンロード
```
状況判断:
- Phase 1では対象外でもOK
- ユーザーからの要望があれば Phase 4 で実装

理由:
- 複雑で工数がかかる
- まずは簡単なMP4ダウンロードで価値を提供
```

#### 2. 著作権保護コンテンツ
```
注意:
- 技術的に可能でも、違法コンテンツのDLは避ける
- 免責事項の表示
  「ユーザーは著作権法を遵守する責任があります」

実装:
- DRM保護コンテンツは自動的にエラー
- 警告ダイアログの表示
```

#### 3. パフォーマンスへの影響
```
懸念:
- Cookie取得は非同期（getAllCookies）
- メインスレッドをブロックしない

対策:
- バックグラウンドキューで処理
- UI更新のみメインスレッド
```

---

## 📋 次のステップ

### 実装前の確認

- [x] 検証結果の整理完了
- [x] 方向性変更の理由を文書化
- [x] 技術的制約の明確化
- [x] 懸念事項の洗い出し
- [x] 既存ダウンロード機能の確認完了
- [ ] ユーザーの承認取得 ← **今ここ**

### 既存ダウンロード機能の確認結果

**既存実装ファイル**:
- [DownloadManager.swift](../../VanishBrowser/VanishBrowser/Services/DownloadManager.swift) - 438行
- [HLSDownloader.swift](../../VanishBrowser/VanishBrowser/Services/HLSDownloader.swift) - 659行

**既に実装されている機能**:
- ✅ 通常ダウンロード（URLSession.shared使用）
- ✅ HLSダウンロード（.m3u8 → MP4変換）
  - TSセグメント結合（libavformat使用）
  - JPEG画像シーケンス→MP4変換（AVAssetWriter使用）
- ✅ ダウンロード進捗表示
- ✅ 一時停止・再開・キャンセル
- ✅ 並列ダウンロード（5並列）
- ✅ ダウンロード完了通知

**確認された問題点**:
```swift
// DownloadManager.swift:67
let task = session.downloadTask(with: url)
// → URLSession.shared を使用
// → WKWebViewのCookieは含まれない

// HLSDownloader.swift:29-34
private lazy var urlSession: URLSession = {
    let config = URLSessionConfiguration.default
    // → WKWebViewのCookieは含まれない
}()
```

**新しい実装の方針**:
1. **既存コードは一切変更しない**
2. **新しいメソッドを追加**:
   ```swift
   // DownloadManager.swift に追加
   func startDownloadWithWKWebViewSession(
       url: URL,
       fileName: String,
       folder: String,
       referrer: String
   )
   ```
3. **条件分岐で使い分け**:
   - Cloudflare保護サイト → 新メソッド（WKWebViewセッション使用）
   - その他 → 既存メソッド（変更なし）

### 実装計画

**Phase 1: WKWebViewセッションDL（1-2日）**
```
Day 1:
- Cookie取得ロジック実装
- HTTPヘッダー付与
- テスト（通常サイト）

Day 2:
- 9animeでテスト
- エラーハンドリング
- 既存機能の動作確認
```

**Phase 2: 長押しDL（1-2日）**
```
Day 3:
- LongPressGestureRecognizer追加
- JavaScript: elementFromPoint実装
- video要素検出

Day 4:
- ダウンロード処理と統合
- UIフィードバック
- テスト
```

**Phase 3: UIエンハンス（2-3日）**
```
Week 2:
- フローティングボタン
- 進捗表示改善
- ダウンロード履歴
```

---

## 📝 まとめ

### 重要な変更点

**技術的方向性**:
```
変更前: カスタムプレーヤーでのストリーミング再生（不可能）
変更後: WKWebViewセッションを使ったダウンロード（可能）
```

**理由**:
1. ✅ 技術的に実現可能
2. ✅ 開発期間が短い（3-5日）
3. ✅ 既存機能を壊さない
4. ✅ Alohaとの競合優位性を確保
5. ✅ ユーザーに価値を提供できる

**懸念事項**:
- HLSダウンロードの複雑性（Phase 4で対応可能）
- Cloudflareレート制限（対策あり）
- DRMコンテンツ（エラー表示で対応）

**避けるべきこと**:
- Private API使用
- AVPlayerでのCloudflare保護動画再生
- 既存機能の大規模変更
- 一気通貫の複雑な実装

---

**次のアクション**: ユーザーの承認を得て実装開始

---

## 🔗 関連ドキュメント

- [FEATURE-011-9anime-fullscreen-video.md](./FEATURE-011-9anime-fullscreen-video.md) - 旧状況ドキュメント
- [competitor-analysis.md](../01-product/competitor-analysis.md) - Aloha Browser分析
