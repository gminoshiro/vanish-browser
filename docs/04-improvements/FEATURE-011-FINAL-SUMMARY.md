# FEATURE-011: 最終検証結果まとめ

**作成日**: 2025-11-13
**ステータス**: ❌ **諦め - 技術的限界により実現不可能**

---

## 🎯 当初の目標

9animeなどCloudflare保護サイトからの動画ダウンロード機能強化

---

## 📝 試したこと・結果

### 試行1: AVPlayerでカスタムプレーヤー再生
**アプローチ**:
- 動画URLを検出
- CustomVideoPlayerView（AVPlayer）で再生
- Cookie転送を試みる

**結果**: ❌ **失敗**
- AVPlayerはWKWebViewのセッション/Cookieを継承できない
- Cloudflareが「ブラウザではない」と判定してブロック
- 技術的に不可能と判明

**証拠**:
```
❌ AVPlayer: 再生失敗
Cloudflare "Attention Required!" ページ
```

---

### 試行2: Private API使用
**アプローチ**:
- WKUIDelegate Private Methods使用
- `_frames` プロパティでiframe内動画URL取得
- Mirror を使ってプロパティ列挙

**結果**: ❌ **失敗**
- iframe内動画URLの取得には成功
- しかしAVPlayerでの再生は失敗（Cookie問題）
- App Store審査リスクあり

**証拠**:
```
✅ [Private API] iframe内動画URL取得成功
❌ 動画再生には失敗（Cloudflareブロック）
```

**保存場所**: git stash@{2} に保存済み（2,507行の実装）

---

### 試行3: NetworkInterceptorScript（XHR/fetch フック）
**アプローチ**:
- JavaScriptでXMLHttpRequest/fetchをフック
- 動画リクエストを検出してSwift側に通知
- URLを取得してURLSessionでダウンロード

**結果**: ❌ **失敗**
- URL検出には成功
- しかしURLSessionでのダウンロードはCloudflareブロック
- URL取得だけでは意味がない

**証拠**:
```
🌐 [XHR] GET https://sunburst93.live/.../master.m3u8
✅ URL検出成功
❌ URLSessionダウンロード → Cloudflareブロック
```

**保存場所**: git stash@{2} に保存済み

---

### 試行4: WKWebView Cookie転送（今回のセッション）
**アプローチ**:
- WKWebsiteDataStore.httpCookieStore からCookie取得
- URLRequestにCookie/User-Agent/Refererを設定
- URLSessionでダウンロード

**結果**: ❌ **失敗**
- プライベートモードでCookie数: 0
- 通常モードでも関連Cookie数: 0
- Cookieが取得できない、または不十分

**証拠**:
```
🍪 取得したCookie数: 0
🍪 関連Cookie数: 0
✅ ダウンロード完了: master.m3u8
（プレイリストファイルのみ、動画本体ではない）
```

**問題点**:
1. 動画URLのドメイン（sunburst93.live）とページドメイン（9animetv.to）が異なる
2. WKWebViewのCookieは9animetv.toのみ
3. sunburst93.liveへのリクエストにはCookieがない

---

### 試行5: カスタムプレーヤー削除 + ダウンロード強化
**アプローチ**:
- カスタムプレーヤーを完全削除
- `.m3u8` でもWKWebViewセッションダウンロード使用
- `dataStore` パラメータ追加でプライベートモード対応

**結果**: ⚠️ **未完成・既存機能も破壊**
- カスタムプレーヤー削除 → 通常サイトの動画再生も不可に
- HLS品質選択機能を削除 → HLSダウンロードが使えない
- ビルド未完了（`dataStore` パラメータでコンパイルエラーの可能性）

**被害**:
- 既存の動画再生機能が壊れた
- 既存のHLSダウンロード機能が壊れた

---

## 🔍 根本原因

### Cloudflareの判定基準
Cloudflareは以下を総合的にチェック:
1. Cookie
2. User-Agent
3. Referer
4. **ブラウザコンテキスト全体**（JavaScript実行環境、TLS fingerprint、etc.）

### URLSession / AVPlayer の限界
- どちらも「ブラウザ」ではなく「別のクライアント」として扱われる
- WKWebViewのセッションを継承できない
- Cookie/User-Agentを転送しても、ブラウザコンテキストが失われる

### 結論
**iOSの技術的制約により、Cloudflare保護サイトからのダウンロードは不可能**

---

## 🚫 試していないこと

### JavaScript内でBlobダウンロード
**アプローチ**:
```javascript
fetch(videoUrl)
  .then(response => response.blob())
  .then(blob => {
    // Base64変換してSwift側に送信
    const reader = new FileReader();
    reader.onload = () => {
      window.webkit.messageHandlers.videoBlob.postMessage(reader.result);
    };
    reader.readAsDataURL(blob);
  });
```

**理由**:
- JavaScript内ならWKWebViewのコンテキストを維持できる
- Cloudflareから見て「ブラウザのリクエスト」

**成功可能性**: 40-50%
- HLS (.m3u8) は複数セグメントなので1つずつBlobダウンロード必要
- 大量のセグメント（数百個）をBase64転送するのは現実的でない
- メモリ使用量が膨大になる

**判断**: 試す価値はあるが、成功してもUX的に問題あり

---

### 動画長押しからのダウンロード
**アプローチ**:
- 動画を長押し
- メニュー表示「動画をダウンロード」
- JavaScript Blobダウンロード

**成功可能性**: 同上（40-50%）

---

## 📊 総括

### 技術的結論
**Cloudflare保護サイトからのダウンロードは、現在のiOS技術では実現困難**

理由:
1. AVPlayer/URLSessionはブラウザコンテキストを持たない
2. WKWebViewのセッション継承が不可能
3. Private APIもApp Store審査でリジェクトリスク

### 残された可能性
1. **JavaScript Blobダウンロード**: 40-50%の成功可能性、しかしUX的に問題
2. **諦める**: 他のバグ修正に時間を使う ← **推奨**

### 所要時間
- 検証時間: 約10時間以上
- 実装コード: 2,500行以上
- 結果: すべて失敗

---

## 💡 学んだこと

1. **Cloudflareは強力**: 単純なCookie転送では突破不可能
2. **iOS の制約**: WKWebView と AVPlayer/URLSession の間に壁がある
3. **技術的限界**: できないことはできない

---

## 📋 次のアクション

### 推奨: この機能を諦める

**理由**:
1. 技術的に実現困難
2. 膨大な時間を費やしても成功確率が低い
3. 他のバグ修正の方がユーザーにとって価値がある

### 代替案
- 9anime以外のサイト（Cloudflare保護なし）でのダウンロード機能は既に動作している
- それで十分とする

---

## 🗂️ 保存場所

- **git stash@{0}**: WIP（今回のセッション）- カスタムプレーヤー削除 + Cookie転送試行（未完成）
- **git stash@{1}**: cookie-transfer-attempt-incomplete
- **git stash@{2}**: fullscreen-video-interception-querySelector-attempt（Private API含む、2,507行）

---

## ✅ 完了

このドキュメントを作成したことで、FEATURE-011の検証は完了とします。

**最終判断**: ❌ **諦め - 技術的に実現不可能**

---

## 📅 最終更新（2025-11-14）

**ユーザーの最終決定**: この機能の開発を正式に中止

**理由**:
- Cloudflare保護サイトからのダウンロードは技術的に実現困難
- 複数の手法を試みたがすべて失敗
- Cookie転送、Private API、XHR/fetchフック、Blob方式すべて効果なし
- 第三者CDNのドメイン不一致問題により根本的に解決不可能

**実装したコードの扱い**:
- JavaScript Blob実装コードは残すが、UIからは削除済み
- WKWebViewセッションダウンロード実装も残すが、使用しない
- 既存のダウンロード機能（Cloudflare保護なしサイト）は正常動作

**今後の方針**:
- この機能は諦め、他のバグ修正・機能改善に注力する
- Cloudflare保護なしのサイトでは既存機能が十分に動作している

---

## 📅 追加検証（2025-11-14）

### 試行: 全画面イベントでのカスタムプレーヤー起動

**目的**: サイト内再生を許可し、全画面時のみカスタムプレーヤーを起動

**変更内容**:
- `play`イベント → `fullscreenchange` + `webkitfullscreenchange` イベントに変更
- 全画面になった瞬間にカスタムプレーヤーを起動する実装

**期待動作**:
- missav.ws, video.dmm.co.jp: 再生ボタン押下 → サイト内再生、全画面ボタン → カスタムプレーヤー起動
- home-movie.biz: DLボタン押下 → カスタムプレーヤー起動（維持）

**結果**: ❌ **失敗 - カスタムプレーヤーが全く起動しない**

**原因推測**:
- `fullscreenchange`イベント自体が発火していない可能性
- WKWebViewの全画面制御とJavaScriptイベントの不一致
- iOSのWebKit特有の制約

**結論**:
- 全画面イベントによるカスタムプレーヤー起動は技術的に困難
- 現状の`play`イベント方式を維持
- これ以上の改修は行わず、現状維持を決定
