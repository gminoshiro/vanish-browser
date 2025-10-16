# BUG-008: HLS動画のMP4ダウンロード非対応

🔴 P0 Critical | ⏳ 動作確認待ち

---

## 問題

HLS動画（.m3u8）を選択してもMP4としてダウンロードできない。
現在はm3u8ファイルとTSセグメントがそのまま保存される。

---

## 実装内容

AVAssetExportSessionを使用したHLS→MP4変換機能を実装しました。

### 変更点

1. **HLSDownloader.swift**: `downloadHLSAsMP4()` メソッドを追加
   - AVAssetExportSessionでHLS URLを直接MP4に変換
   - 進捗監視機能（0.1秒ごと）
   - エクスポート結果のエラーハンドリング

2. **QualitySelectionView.swift**: ダウンロード形式選択機能を追加
   - MP4形式/m3u8形式の選択（デフォルト: MP4）
   - セグメント型ピッカーで切り替え
   - 各形式の説明テキスト付き

3. **DownloadDialogView.swift**: 形式パラメータを追加
   - `onHLSDownload` に `DownloadFormat` を追加

4. **BrowserView.swift**: MP4/m3u8の分岐処理を追加
   - `handleHLSDownload()` でformat判定
   - MP4: `downloadHLSAsMP4()` 呼び出し
   - m3u8: 既存の `downloadHLS()` 呼び出し

---

## 関連ファイル

- [HLSDownloader.swift](../../VanishBrowser/VanishBrowser/Services/HLSDownloader.swift)
- [HLSParser.swift](../../VanishBrowser/VanishBrowser/Services/HLSParser.swift)
- [DownloadDialogView.swift](../../VanishBrowser/VanishBrowser/Views/DownloadDialogView.swift)
