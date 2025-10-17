# BUG-008: HLS動画のMP4ダウンロード非対応

🔴 P0 Critical | ❌ **技術的制約により対応困難**

---

## 問題

HLS動画（.m3u8）をMP4形式でダウンロードできない。

---

## 調査結果

### 1. m3u8形式でのダウンロード（以前実装済み）

**結果: 失敗 ❌**

- m3u8ファイルとTSセグメントをダウンロード
- ダウンロード後、ローカルで再生できない
- セグメントファイルのパス解決に失敗
- **結論**: m3u8形式のダウンロードは実用的ではない

### 2. MP4変換ダウンロード（AVAssetExportSession使用）

**結果: DRM保護動画で失敗 ❌**

#### 実装内容

- AVAssetExportSessionを使用したHLS→MP4変換
- `downloadHLSAsMP4()` メソッドを実装
- 進捗監視機能付き

#### エラー内容

```
❌ HLSダウンロードエラー: Error Domain=HLSDownloader Code=-1
"この動画はエクスポートできません"
UserInfo={NSLocalizedDescription=この動画はエクスポートできません}
```

#### 失敗理由

1. **DRM保護**: DMMなどの動画サイトはDRM保護を使用
2. **AVAssetExportSessionの制限**: DRM保護された動画には対応していない
3. **トークン認証**: セグメントURLが時間制限付きトークンで保護されている可能性

---

## 技術的制約

### Appleの公式APIの制限

- **AVAssetExportSession**: DRM保護動画に非対応
- **AVAssetDownloadTask**: オフライン再生用だが、同様にDRM制約あり
- **URLSession直接ダウンロード**: セグメント暗号化・トークン認証で不可能

### 法的問題

- DRM回避は違法
- サードパーティライブラリの使用はApp Store審査で却下される可能性

---

## 代替案

### 実現可能性: 低

1. **画面録画機能（ReplayKit）**
   - メリット: 任意の動画を録画可能
   - デメリット: 画質劣化、操作が煩雑、著作権問題

2. **m3u8形式での保存（改善版）**
   - メリット: セグメントファイルをローカル保存
   - デメリット: 以前試して再生失敗、複雑な実装が必要

---

## 重要な情報

### Alohaブラウザでは実現できている

**事実**: Alohaブラウザは同じDMM動画サイトでHLSダウンロードに成功している

これは以下のいずれかを意味する：

1. **独自のHLS処理実装**
   - セグメントファイルを個別にダウンロード
   - ローカルで再生可能なファイル構造を構築
   - 相対パスの解決を独自実装

2. **FFmpegなどの外部ライブラリ使用**
   - C/C++ライブラリをSwiftにブリッジ
   - HLS→MP4変換をネイティブレベルで実装
   - App Store審査を通過している実績あり

3. **WebKitのキャッシュ機能活用**
   - 再生中にキャッシュされたセグメントを取得
   - キャッシュから動画ファイルを再構築

---

## 今後の対応方針

### ✅ 実現可能性: 中〜高

Alohaが実現している以上、技術的には可能。以下の方法を検討：

1. **FFmpegの組み込み** (推奨)
   - ライブラリ: `ffmpeg-kit-ios-https`
   - 実績: 多くのiOSアプリで使用、App Store審査通過例多数
   - メリット: HLS→MP4変換が確実、高品質
   - デメリット: アプリサイズ増加（約10-20MB）、実装複雑

2. **独自HLS処理実装**
   - セグメント個別ダウンロード
   - ローカルm3u8ファイルの再生可能な構造構築
   - メリット: 外部ライブラリ不要
   - デメリット: 実装が複雑、メンテナンスコスト高

3. **WebKitキャッシュからの抽出**
   - AVPlayerが再生中にキャッシュしたセグメントを取得
   - メリット: 既存の仕組みを活用
   - デメリット: Appleの非公開APIに依存する可能性、不安定

---

## ✅ 解決済み (2025-10-17)

**FFmpegを使用したHLS→MP4変換に成功**

### 最終実装

**FFmpeg統合による完全な解決**
- ✅ `kewlbear/FFmpeg-iOS` (Swift Package Manager)
- ✅ `kewlbear/FFmpeg-iOS-Support`
- ✅ TSセグメント結合 → FFmpegでMP4変換
- ✅ iOSネイティブプレイヤーで再生可能

### 実装の詳細

1. **TSセグメントダウンロード**
   - HLSプレイリストから全セグメント取得
   - 一時フォルダに順次ダウンロード

2. **FFmpeg変換**
   ```swift
   ffmpeg([
       "ffmpeg",
       "-i", "input.ts",
       "-c", "copy",  // 再エンコードなし（高速）
       "-y",
       "output.mp4"
   ])
   ```

3. **ファイル管理**
   - 一時フォルダで作業
   - `Downloads/`直下に最終MP4保存
   - 一時ファイル自動削除

### テスト結果

- ✅ HLS動画のMP4変換成功
- ✅ ダウンロード後にiOSで再生可能
- ✅ Alohaブラウザと同等の機能を実現

---

## ⚠️ 重要な注意事項

### 1. ライセンスに関する制約

**FFmpegのライセンス**
- FFmpegは **GPL (GNU General Public License)** または **LGPL** ライセンス
- 使用している `FFmpeg-iOS` は **GPL** コンポーネントを含む可能性あり

**アプリへの影響**
- ✅ **個人使用・オープンソース**: 問題なし
- ⚠️ **App Store配信**: 以下の対応が必要
  - アプリ自体もGPLライセンスとして公開
  - ソースコード全体の公開義務
  - または、LGPLのみの構成でFFmpegをビルド

**推奨対応**
1. アプリをオープンソースとして公開（GPLライセンス）
2. または、商用利用の場合はLGPL版FFmpegの使用を検討
3. App Store審査時にライセンス明記

### 2. パフォーマンスへの影響

**アプリサイズ**
- FFmpegライブラリ: 約 **10-20MB** 増加
- XCFramework全体: 約 **15-25MB**

**変換速度**
- `-c copy` (コーデックコピー): 高速（数秒）
- 再エンコード不要のため品質劣化なし
- 長時間動画（1時間以上）でも数十秒程度

### 3. App Store審査への対応

**必要な記載事項**
- App Storeの説明文にライセンス情報を記載
- アプリ内のAbout/Settingsにライセンス表示
- 以下のライブラリ使用を明記:
  - FFmpeg (GPL/LGPL)
  - FFmpeg-iOS by kewlbear

**審査で確認される可能性があるポイント**
- ライセンス準拠の確認
- ソースコード公開の有無（GPLの場合）
- サードパーティライブラリの適切な表示

---

## 実装履歴

### 2025-10-17: FFmpeg統合による解決

1. **Swift Package Manager でFFmpeg追加**
   - `kewlbear/FFmpeg-iOS@0.0.6-b`
   - `kewlbear/FFmpeg-iOS-Support@0.0.2`

2. **HLSDownloader.swift 更新**
   - `convertTSToMP4WithFFmpeg()` メソッド追加
   - FFmpegコマンド実行: `ffmpeg -i input.ts -c copy output.mp4`
   - 一時フォルダでの作業フロー実装

3. **ファイル構造改善**
   - 一時フォルダ: `Downloads/_temp_{videoName}_{UUID}`
   - 最終保存先: `Downloads/{videoName}.mp4`
   - 自動クリーンアップ

### 以前の試行（失敗）

1. **AVAssetExportSession**: DRM保護動画で失敗（error -12847）
2. **AVAssetWriter**: TS形式を認識できず失敗（error -12848）
3. **ローカルm3u8**: 再生時にパス解決失敗（error -12865）

---

## 関連ファイル

- [HLSDownloader.swift](../../VanishBrowser/VanishBrowser/Services/HLSDownloader.swift)
- [HLSParser.swift](../../VanishBrowser/VanishBrowser/Services/HLSParser.swift)
- [DownloadDialogView.swift](../../VanishBrowser/VanishBrowser/Views/DownloadDialogView.swift)
