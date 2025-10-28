# FEATURE-010: 写真アプリからの共有でアプリへコピー

🟡 P2 Medium | ⚠️ 部分実装（onOpenURLのみ、Share Extension未実装）

---

## 要望

写真アプリから共有ボタンでアプリへのコピーができるようになっていない。

---

## 実装内容

Share Extensionを実装して、写真アプリからVanishブラウザのダウンロードフォルダに画像・動画をコピーできるようにする。

---

## 実装ステップ

1. **Share Extension ターゲット追加**
   - Xcode → File → New → Target → Share Extension

2. **UTTypeの対応**
   - 画像: `public.image`
   - 動画: `public.movie`

3. **DownloadServiceとの連携**
   - App Groupを使用してダウンロードフォルダを共有
   - Share Extensionから画像・動画をコピー

4. **Info.plist設定**
   ```xml
   <key>NSExtensionActivationRule</key>
   <dict>
       <key>NSExtensionActivationSupportsImageWithMaxCount</key>
       <integer>10</integer>
       <key>NSExtensionActivationSupportsMovieWithMaxCount</key>
       <integer>10</integer>
   </dict>
   ```

---

## 参考

- [FEATURE-004](FEATURE-004-file-import-export.md) iOS写真・ファイル転送機能

---

## 作成日

2025-10-19
