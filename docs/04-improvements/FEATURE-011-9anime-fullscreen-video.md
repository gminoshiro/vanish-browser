# FEATURE-011: 9anime全画面動画 → DL機能強化へ方向転換

**最終更新**: 2025-11-12
**ステータス**: 🔄 **方向性変更 - DL機能強化へ**

---

## 🚨 重要なお知らせ

**このドキュメントは古い検証記録です。**

**最新の意思決定と実装計画は以下を参照してください**:
👉 [FEATURE-011-VERIFICATION-AND-DECISION.md](./FEATURE-011-VERIFICATION-AND-DECISION.md)

---

## 🎯 最終目標（変更前 - 実現不可能と判明）

9animeでネイティブの再生ボタンをタップ → Aloha Browser風のカスタム全画面プレーヤーで再生

## 🎯 新しい目標（変更後 - 実現可能）

9animeなどCloudflare保護サイトからの動画ダウンロード機能強化
- WKWebViewのセッションを使った動画ダウンロード
- 再生中動画の長押しダウンロード
- 既存のダウンロード機能は完全に保持

---

## ✅ できていること（動作確認済み）

### 1. 動画検出 ✅
```
場所: BrowserViewModel.swift - userContentController
イベント: videoDetected メッセージハンドラー
結果: ✅ 動画URLを正しく検出
ログ: 🎬 動画検出: master.m3u8 - URL: https://...
```

### 2. 再生ボタンイベント取得 ✅
```
場所: WebViewConfigurator.swift - mediaDetectionScript
JavaScript: video.addEventListener('play', ...)
結果: ✅ play イベントを正しく検出
ログ: 🎬 Video play intercepted: https://...
```

### 3. クリックイベント取得 ✅
```
場所: WebViewConfigurator.swift - mediaDetectionScript
JavaScript: video.addEventListener('click', handleVideoClick)
結果: ✅ click イベントを正しく検出
ログ: 🎬 Video clicked: https://...
```

### 4. 全画面イベント取得 ✅ (git stash内で確認)
```
場所: git stash@{0} - BrowserViewModel.swift
JavaScript: video.addEventListener('webkitbeginfullscreen', ...)
            document.addEventListener('fullscreenchange', ...)
結果: ✅ 全画面イベントを正しく検出
ログ: 🎬🎬🎬 webkitbeginfullscreen イベント発火!
      📺📺📺 fullscreenchange イベント発火!
```

### 5. カスタムプレーヤー起動 ✅
```
場所: BrowserView.swift - fullScreenCover
結果: ✅ CustomVideoPlayerView が正常に起動
ログ: 🎬 CustomVideoPlayerView初期化
```

### 6. NetworkInterceptorScript ✅ (git stash内)
```
場所: git stash@{0} - VideoURLSchemeHandler.swift
機能: XHR/fetch フック、HTMLMediaElement.src フック、MutationObserver
結果: ✅ 実装完了（2,507行）
ログ: 🔧 [NetworkInterceptor] スクリプト開始
      🎥 [NetworkInterceptor] 動画URL検出 (XHR): https://...
```

---

## ❌ できていないこと（問題点）

### 🔴 **唯一の問題**: 全画面を閉じた後のCloudflareエラー

**重要**: 前回セッションでは動画再生自体は**成功していた**

```
前回セッションの動作:
1. ✅ querySelector で動画検出 - 成功
2. ✅ カスタムプレーヤー起動 - 成功
3. ✅ 動画再生 - 成功
4. ❌ 全画面を閉じる → Cloudflareエラー画面 ← **唯一の問題**

ユーザー報告:
「全画面閉じたらエラー画面でした」
```

**症状**:
- カスタムプレーヤーで動画は正常に再生される
- ×ボタンで全画面を閉じる
- ブラウザに戻ると Cloudflare "Sorry, you have been blocked" 画面が表示

**場所**: BrowserView.swift - fullScreenCover の終了処理

**原因（推測）**:
1. WKWebView のページが reload されている？
2. JavaScript の全画面終了イベントが誤動作？
3. Cookie が削除されている？
4. WKWebView の状態が破損している？

---

### ❌ git stash内の試行結果

#### Private API試行（git stash@{0}）
```
実装: iframe内動画URL取得のためPrivate APIを使用
結果:
  ✅ iframe内動画URLの取得には成功
  ❌ 動画再生には失敗

エラーメッセージ:
「動画の再生に失敗しました。この動画は保護されているため、
 ダウンロードまたは再生できない可能性があります。」

結論: Private APIでもCloudflareブロックは回避できなかった
理由: iframe内URLを取得できても、AVPlayerのHTTPリクエストに
      Cookieが含まれていないため同じ問題が発生
```

#### NetworkInterceptorScript試行（git stash@{0}）
```
実装: XHR/fetchフック、MutationObserver、全画面イベント監視
結果: 動画URL検出には成功したが、再生問題は未解決
結論: URL取得方法を変えても根本問題（Cookie転送）は解決しない
```

### 問題3: iframe内動画へのアクセス 🟡
```
症状: querySelector で動画要素が見つからない
場所: WKWebViewFullscreenPlayerView.swift - enterFullscreen
原因: 9animeの動画は iframe 内にあり、cross-origin 制限でアクセス不可

試行した解決策:
❌ document.querySelectorAll('video') → iframe内は検出できない
❌ forMainFrameOnly: false → iframe内DOMは操作できない
✅ Private API (git stash内) → 試行済みだが結果不明
```

---

## 📦 git stash@{0} で試行した内容（詳細）

### 1. Private API 使用 ✅ **試行済み**

**実装規模**: 2,507行（大規模実装）

**試行した Private API**:
```swift
// WKUIDelegate Private Methods
_willEnterFullScreenWithCallback
_webViewWillEnterFullScreen
_webViewDidEnterFullScreen
willEnterElementFullscreen
didExitElementFullscreen

// WKWebView Private Properties
_frames
_contentView

// iframe内動画URL抽出
func extractVideoURLFromFrames() {
    // _frames プロパティから動画URLを抽出
    // Mirror を使ってプロパティを列挙
    // セレクタ実行で動画要素にアクセス
}
```

**ログから判明した動作**:
```
🔓🔓🔓 [Private API] フルスクリーン完了後のiframe内動画検出を試行
✅✅✅ [Private API] iframe内動画URL取得成功: https://...
```

**結果**: ⚠️ **一部成功したがstashされた** → 理由不明

**推測**:
- iframe内動画URLの取得には成功した
- しかしCloudflare問題で再生できなかった？
- またはApp Store審査を懸念してstash？

### 2. 全画面イベント監視 ✅ **実装完了**

**実装内容**:
```javascript
// webkitbeginfullscreen を preventDefault でブロック
video.addEventListener('webkitbeginfullscreen', function(e) {
    e.preventDefault();
    e.stopPropagation();
    // カスタムプレーヤー起動
    window.webkit.messageHandlers.videoFullscreenStarted.postMessage({
        url: videoUrl,
        fileName: fileName
    });
}, true);

// fullscreenchange も監視
document.addEventListener('fullscreenchange', function() {
    const fullscreenElement = document.fullscreenElement;
    if (fullscreenElement && fullscreenElement.tagName === 'VIDEO') {
        // カスタムプレーヤー起動
    }
}, true);
```

**動作**: ✅ イベントは正しく検出される

### 3. NetworkInterceptorScript ✅ **実装完了**

**機能**:
- XHR/fetch フック
- HTMLMediaElement.src フック
- MutationObserver でDOM監視
- iframe内でも動作 (forMainFrameOnly: false)

**動作**: ✅ 動画URLは検出される

**しかし**: ❌ Cloudflare問題は未解決

---

## 🔍 問題の本質

### すべての道が Cloudflare に通じる

```
[フロー図]

1. ✅ 動画検出 (querySelector / NetworkInterceptor / Private API)
2. ✅ イベント取得 (play / click / fullscreen)
3. ✅ カスタムプレーヤー起動
4. ❌ AVPlayer で再生 → Cloudflare ブロック ← **ここで止まっている**
5. ❌ 全画面を閉じる → Cloudflare エラー ← **副次的問題**
```

**結論**: どの方法でも Cookie転送 を解決しない限り進めない

---

## 🎯 次の一手（優先順位順）

### 優先度1: 全画面を閉じた後のエラー調査 🔴 **最優先**

**理由**: 前回セッションでは動画再生は成功していた。問題は全画面終了時のみ。

**現在の実装を確認**:

**調査項目**:
```swift
// BrowserView.swift - fullScreenCover
.fullScreenCover(isPresented: $showCustomVideoPlayer) {
    // ...
}
.onDisappear {
    print("📊 fullScreenCover.onDisappear")
    print("📊 webView.url: \(viewModel.webView.url?.absoluteString ?? "nil")")
    print("📊 webView.isLoading: \(viewModel.webView.isLoading)")
    // WKWebView の状態を確認
}
```

**仮説1**: WKWebView が reload されている
- 確認: `webView.url` が変わっているか？

**仮説2**: Cookie が削除されている
- 確認: `WKWebsiteDataStore.httpCookieStore` に Cookie が残っているか？

**仮説3**: 全画面終了イベントの処理ミス
- 確認: `videoFullscreenEnded` メッセージハンドラーの処理

---

### 優先度3: git stash の Private API 実装を再検証 ⏸️

**目的**: なぜ stash されたのかを理解する

**調査**:
1. stash を適用してビルド
2. 9anime でテスト
3. ログを詳細に確認
4. 失敗した箇所を特定

**注意**: App Store 審査リスクあり（最終手段）

---

## 📝 作業ルール

### 修正時の必須手順

1. **このファイルを必ず参照**
   - 過去の失敗を繰り返さない
   - 「できていること」を壊さない

2. **1つずつ段階的に修正**
   ```
   ステップ1: Cookie取得のログ確認
   ステップ2: AVPlayerへのCookie設定確認
   ステップ3: HTTPリクエストヘッダー確認
   ステップ4: Cloudflareエラーの有無確認
   ```

3. **ログを詳細に記録**
   ```swift
   print("🍪 Cookie数: \(cookies.count)")
   print("🍪 Cookie内容: \(cookieString.prefix(200))")
   print("🎥 AVURLAsset作成: \(url.absoluteString)")
   print("🎥 HTTPヘッダー: \(headers)")
   ```

4. **このファイルを更新**
   - 試行結果を記録
   - 成功/失敗を明記
   - 次のステップを更新

---

## 📊 チェックリスト

### WKWebsiteDataStore Cookie取得
- [ ] `getAllCookies` で Cookie 取得
- [ ] ドメインフィルタリング（url.hostと一致）
- [ ] Cookie文字列生成
- [ ] ログで Cookie 内容確認
- [ ] User-Agent も追加
- [ ] AVURLAsset に設定
- [ ] ビルド成功
- [ ] 9anime でテスト
- [ ] Cloudflare ブロック解除確認

### 全画面終了後エラー調査
- [ ] `.onDisappear` でログ追加
- [ ] `webView.url` 確認
- [ ] `webView.isLoading` 確認
- [ ] Cookie 残存確認
- [ ] エラーの再現条件特定

---

## 📦 git stash 一覧

### stash@{0}: cookie-transfer-attempt-incomplete
```
内容: WKWebViewFullscreenPlayerView + Cookie転送試行
状態: 不完全（querySelector では iframe内動画にアクセスできない）
結果: 動画が見つからないエラー
結論: 間違ったアプローチ
```

### stash@{1}: fullscreen-video-interception-querySelector-attempt
```
内容: 包括的な実装（1,450行追加、467行削除）
  - NetworkInterceptorScript (XHR/fetch フック)
  - 全画面イベント監視 (webkitbeginfullscreen/fullscreenchange)
  - UIWindow監視 (AVPlayerViewController検出)
  - カスタムプレーヤー起動 (fullScreenCover)
  - Cookie転送試行 (HTTPCookieStorage.shared使用)

状態: 包括的実装完了
結果:
  ✅ 動画URL検出成功
  ✅ 全画面イベント取得成功
  ✅ カスタムプレーヤー起動成功
  ❌ Cookie転送失敗 → Cloudflareブロック
  ❌ 全画面終了後にCloudflareエラー

詳細: FEATURE-011-DETAILED-ANALYSIS.md 参照
```

---

## 🔗 関連ファイル

- [CustomVideoPlayerView.swift:302-330](../../VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift#L302-L330)
- [BrowserView.swift:538-546](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift#L538-L546)
- [BrowserViewModel.swift](../../VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift) - メッセージハンドラー実装
- [VideoURLSchemeHandler.swift](../../VanishBrowser/VanishBrowser/Services/VideoURLSchemeHandler.swift) - NetworkInterceptorScript

---

## 📊 現在の状況（2025-11-12）

### 現在適用されているコード
- git stash@{1} が適用された状態
- 包括的な全画面インターセプト実装が含まれる
- Cookie転送は HTTPCookieStorage.shared 使用（不完全）

### 次のアクション

**優先度1: 前回セッションの成功を再現**
```
前回は「全画面閉じたらエラー画面」= 動画再生自体は成功していた
→ なぜ成功したのか？Cookie転送の実装が異なっていた？
→ ログを確認して成功要因を特定する必要がある
```

**優先度2: 全画面終了時のエラー調査**
```swift
// BrowserView.swift - fullScreenCover の .onDisappear に追加
.onDisappear {
    print("📊 fullScreenCover.onDisappear")
    print("📊 webView.url: \(viewModel.webView.url?.absoluteString ?? "nil")")
    print("📊 webView.isLoading: \(viewModel.webView.isLoading)")

    // Cookie 残存確認
    WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
        print("📊 Cookie数: \(cookies.count)")
    }
}
```

**優先度3: Cookie転送の修正（必要な場合）**
```swift
// WKWebsiteDataStore から Cookie 取得
WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
    let cookieString = cookies
        .filter { $0.domain.contains(url.host ?? "") }
        .map { "\($0.name)=\($0.value)" }
        .joined(separator: "; ")

    let headers = ["Cookie": cookieString, "User-Agent": userAgent]
    let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
}
```
