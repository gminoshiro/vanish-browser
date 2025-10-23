# QUESTION-002: 共有候補にアプリが表示されない

🟢 Question | ✅ 調査完了

---

## 質問

写真やファイルアプリから画像・動画を共有ボタンで開こうとしても、本アプリが候補に出ない。開発中だから？

---

## 調査結果

1. **実装状況**
   - [VanishBrowserApp.swift:25-27](../../VanishBrowser/VanishBrowser/VanishBrowserApp.swift#L25-L27)で`.onOpenURL`は実装済み
   - ファイル受信処理は実装済み（画像・動画対応）

2. **不足している設定**
   - **Info.plistのDocument Types設定が未実装**
   - CFBundleDocumentTypes（サポートするファイルタイプ）が未定義
   - UTI（Uniform Type Identifier）の宣言が必要

3. **解決策**
   Xcodeプロジェクト設定で以下を追加：
   - **Document Types**に画像・動画のUTIを登録
     - public.image (画像全般)
     - public.movie (動画全般)
     - public.jpeg, public.png, public.mpeg-4など
   - ロールを「Viewer」または「Editor」に設定

---

## 実装方法

Xcodeで以下の手順を実行：

1. プロジェクト設定 > VanishBrowser target > Info タブ
2. **Document Types** セクションを追加
3. 以下のUTIを追加：
   ```
   - Name: Images
     Types: public.image, public.jpeg, public.png
     Role: Viewer

   - Name: Videos
     Types: public.movie, public.mpeg-4
     Role: Viewer
   ```

または、Info.plistに直接追加：
```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Images</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.image</string>
            <string>public.jpeg</string>
            <string>public.png</string>
        </array>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
    </dict>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Videos</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.movie</string>
            <string>public.mpeg-4</string>
        </array>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
    </dict>
</array>
```

---

## 注意点

- 開発中のアプリでも設定があれば共有候補に表示される
- TestFlightビルドやリリースビルドで動作確認を推奨
- Share Extensionターゲットは不要（Document TypesのみでOK）

---

## 関連ファイル

- [VanishBrowserApp.swift](../../VanishBrowser/VanishBrowser/VanishBrowserApp.swift)
