# FEATURE-001: デフォルトブラウザをセキュリティの高いブラウザに設定

🟡 P2 Medium | ⏳ 動作確認待ち (Info.plist設定が必要)

---

## 問題

デフォルトブラウザの設定がない、またはセキュリティの低いブラウザが設定されている。

---

## 実装内容

VanishBrowserをデフォルトブラウザとして設定できる機能を追加しました。

### 変更点

1. **SettingsView.swift**: デフォルトブラウザ設定セクションを追加
   - 「デフォルトブラウザに設定」ボタンを追加
   - タップするとiOS設定アプリを開く
   - 説明文を追加

2. **VanishBrowserApp.swift**: 外部URLハンドリングを追加
   - `onOpenURL`でHTTP/HTTPSスキームを検出
   - `OpenExternalURL`通知を送信してブラウザで開く

3. **BrowserView.swift**: 外部URL通知を受信
   - `OpenExternalURL`通知を受信
   - `viewModel.loadURL()`でURLを開く

### 必要な設定

**Info.plistに以下の設定が必要です:**

詳細は [DEFAULT_BROWSER_SETUP.md](../../03-setup/DEFAULT_BROWSER_SETUP.md) を参照してください。

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Browser</string>
        <key>CFBundleURLName</key>
        <string>Web Browser</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>http</string>
            <string>https</string>
        </array>
    </dict>
</array>
```

---

## 関連ファイル

- [SettingsView.swift](../../VanishBrowser/VanishBrowser/Views/SettingsView.swift)
