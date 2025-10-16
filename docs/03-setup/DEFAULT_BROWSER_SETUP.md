# デフォルトブラウザ設定手順

VanishBrowserをデフォルトブラウザとして設定できるようにするための手順です。

---

## Info.plist設定

Xcodeプロジェクトで以下の設定を追加する必要があります:

1. Xcodeで `VanishBrowser.xcodeproj` を開く
2. プロジェクトナビゲータで `VanishBrowser` ターゲットを選択
3. `Info` タブを選択
4. 以下のキーを追加:

### LSSupportsOpeningDocumentsInPlace
- Type: Boolean
- Value: YES

### CFBundleDocumentTypes
- Type: Array
- Item 0:
  - Type: Dictionary
  - CFBundleTypeName: Web Page
  - LSItemContentTypes: Array
    - public.html
    - public.url
    - public.xhtml

### CFBundleURLTypes
- Type: Array
- Item 0:
  - Type: Dictionary
  - CFBundleTypeRole: Browser
  - CFBundleURLName: Web Browser
  - CFBundleURLSchemes: Array
    - http
    - https

---

## または、Info.plistを直接編集

```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>

<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Web Page</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.html</string>
            <string>public.url</string>
            <string>public.xhtml</string>
        </array>
    </dict>
</array>

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

## アプリ内設定

設定画面に「デフォルトブラウザに設定」ボタンが追加されています。
このボタンをタップすると、iOSの設定アプリが開き、デフォルトブラウザを変更できます。

**設定手順:**
1. VanishBrowserの設定画面を開く
2. 「デフォルトブラウザに設定」をタップ
3. iOSの設定アプリが開く
4. 「デフォルトのブラウザApp」をタップ
5. 「Vanish Browser」を選択

---

## 注意事項

- iOS 14以降でのみ利用可能
- デフォルトブラウザに設定すると、他のアプリでリンクをタップしたときにVanishBrowserで開きます
- いつでもiOSの設定から変更できます
