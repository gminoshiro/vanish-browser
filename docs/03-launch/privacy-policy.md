# プライバシーポリシー / Privacy Policy

**最終更新 / Last Updated**: 2025年10月8日 / October 8, 2025

---

## 日本語版

### Vanish Browser プライバシーポリシー

Vanish Browser（以下「当アプリ」）は、ユーザーのプライバシー保護を最優先に設計されたiOSアプリケーションです。
本プライバシーポリシーでは、当アプリがどのようにユーザーの情報を扱うかを説明します。

---

### 1. 収集する情報

**当アプリは、ユーザーの個人情報を一切収集しません。**

具体的には、以下のデータを収集しません：

| データ種別 | 収集 | 説明 |
|-----------|------|------|
| **閲覧履歴** | ❌ 収集しない | Webサイトの閲覧履歴はローカルに保存されますが、外部送信されません |
| **ダウンロード履歴** | ❌ 収集しない | ダウンロードしたファイルの情報はローカルのみに保存されます |
| **検索キーワード** | ❌ 収集しない | 検索エンジン（DuckDuckGo等）への送信のみ行われます |
| **位置情報** | ❌ 収集しない | 当アプリは位置情報を使用しません |
| **連絡先** | ❌ 収集しない | 当アプリは連絡先にアクセスしません |
| **写真** | ❌ 収集しない | ダウンロード保存のみ行い、外部送信しません |
| **識別子** | ❌ 収集しない | 広告IDやデバイスID等を収集しません |
| **使用状況データ** | ❌ 収集しない | アクセス解析ツールを使用していません |
| **クラッシュログ** | ❌ 収集しない | Phase 2以降で検討予定 |

---

### 2. データの使用目的

**当アプリは、ユーザーのデータを外部サーバーに送信しません。**

すべてのデータは、以下の目的でのみローカルに保存されます：

- Webページの表示
- ダウンロードファイルの管理
- ブックマークの保存
- アプリ設定の保持
- 自動削除機能の実行

---

### 3. データの保存場所

すべてのデータは、**ユーザーのiPhone/iPad内にのみ保存**されます。

| データ種別 | 保存場所 | 暗号化 | iCloudバックアップ |
|-----------|---------|--------|------------------|
| **ダウンロードファイル** | ローカルストレージ | ✅ AES-256 | ❌ 除外 |
| **ブックマーク** | Core Data | ✅ iOS標準 | ✅ 含む |
| **アプリ設定** | UserDefaults | ✅ iOS標準 | ✅ 含む |
| **暗号化鍵** | Keychain | ✅ Keychain | ✅ 含む |

**iCloudバックアップからの除外**:
- ダウンロードしたファイルは、iCloudバックアップから明示的に除外されます
- これにより、デジタル遺品がクラウドに残ることを防ぎます

---

### 4. 第三者への提供

**当アプリは、ユーザーのデータを第三者に提供しません。**

以下のサービスも使用していません：

- ❌ Google Analytics
- ❌ Firebase Crashlytics
- ❌ Facebook SDK
- ❌ 広告SDK
- ❌ その他のトラッキングツール

---

### 5. セキュリティ

当アプリは、以下のセキュリティ対策を実装しています：

#### 5.1 暗号化
- **ファイル暗号化**: AES-256-GCM方式
- **暗号化鍵**: Keychainで安全に保存
- **Core Data**: iOS標準のファイルレベル暗号化

#### 5.2 生体認証
- **Face ID / Touch ID**: アプリ起動時の認証
- **パスコード**: 生体認証非対応デバイスでのフォールバック

#### 5.3 通信セキュリティ
- **HTTPS強制**: すべての通信をHTTPS経由
- **証明書検証**: 無効な証明書をブロック

---

### 6. Cookie（クッキー）

当アプリは、Webサイト閲覧時に以下のCookie管理を行います：

- **セッションCookie**: 許可（Webサイト動作に必要）
- **サードパーティCookie**: ブロック
- **Cookie削除**: アプリ終了時または手動削除可能

---

### 7. 自動削除機能

当アプリの特徴である「自動削除機能」について：

- **削除条件**: 90日間アプリを起動しなかった場合
- **削除対象**: すべてのダウンロードファイル、閲覧履歴、ブックマーク、設定
- **通知**: 削除7日前にプッシュ通知
- **復元**: 削除後の復元は不可能

この機能は、ユーザーが突然の事故や病気でアプリを使用できなくなった際に、
デジタル遺品を残さないために設計されています。

---

### 8. ユーザーの権利

#### 8.1 データ削除権
ユーザーは、いつでも以下の方法でデータを削除できます：

1. **アプリ内削除**: 設定画面から「すべてのファイルを削除」
2. **アプリ削除**: iPhoneからアプリをアンインストール

#### 8.2 データポータビリティ
現時点では、データのエクスポート機能は提供していません（Phase 2で検討）。

---

### 9. 子どものプライバシー

当アプリは、13歳未満の子どもを対象としていません。
13歳未満の方が誤って使用した場合でも、個人情報は収集されません。

---

### 10. プライバシーポリシーの変更

本プライバシーポリシーは、必要に応じて変更される場合があります。
重要な変更がある場合は、アプリ内通知またはApp Storeの説明文で通知します。

---

### 11. お問い合わせ

プライバシーに関するご質問は、以下までお願いします：

- **Email**: support@vanishbrowser.com（後で追加）
- **GitHub**: https://github.com/YOUR_USERNAME/vanish-browser/issues

---

### 12. 準拠法

本プライバシーポリシーは、日本法に準拠します。

---

## English Version

### Vanish Browser Privacy Policy

Vanish Browser (the "App") is an iOS application designed with user privacy as the top priority.
This Privacy Policy explains how the App handles user information.

---

### 1. Information We Collect

**The App does NOT collect any personal information.**

Specifically, we do not collect:

| Data Type | Collected | Description |
|-----------|-----------|-------------|
| **Browsing History** | ❌ No | Stored locally only, never transmitted externally |
| **Download History** | ❌ No | Stored locally only |
| **Search Keywords** | ❌ No | Only sent to search engines (e.g., DuckDuckGo) |
| **Location** | ❌ No | The App does not use location services |
| **Contacts** | ❌ No | The App does not access contacts |
| **Photos** | ❌ No | Downloads only, no external transmission |
| **Identifiers** | ❌ No | No advertising IDs or device IDs collected |
| **Usage Data** | ❌ No | No analytics tools used |
| **Crash Logs** | ❌ No | Under consideration for Phase 2 |

---

### 2. How We Use Data

**The App does NOT transmit user data to external servers.**

All data is stored locally for the following purposes:

- Displaying web pages
- Managing downloaded files
- Saving bookmarks
- Storing app settings
- Executing auto-delete functionality

---

### 3. Data Storage

All data is **stored only on the user's iPhone/iPad**.

| Data Type | Storage | Encryption | iCloud Backup |
|-----------|---------|------------|---------------|
| **Downloaded Files** | Local Storage | ✅ AES-256 | ❌ Excluded |
| **Bookmarks** | Core Data | ✅ iOS Standard | ✅ Included |
| **App Settings** | UserDefaults | ✅ iOS Standard | ✅ Included |
| **Encryption Keys** | Keychain | ✅ Keychain | ✅ Included |

**iCloud Backup Exclusion**:
- Downloaded files are explicitly excluded from iCloud backup
- This prevents digital legacy from remaining in the cloud

---

### 4. Third-Party Sharing

**The App does NOT share user data with third parties.**

We do not use the following services:

- ❌ Google Analytics
- ❌ Firebase Crashlytics
- ❌ Facebook SDK
- ❌ Advertising SDKs
- ❌ Any tracking tools

---

### 5. Security

The App implements the following security measures:

#### 5.1 Encryption
- **File Encryption**: AES-256-GCM
- **Encryption Keys**: Securely stored in Keychain
- **Core Data**: iOS standard file-level encryption

#### 5.2 Biometric Authentication
- **Face ID / Touch ID**: Authentication on app launch
- **Passcode**: Fallback for non-biometric devices

#### 5.3 Communication Security
- **HTTPS Enforced**: All communications via HTTPS
- **Certificate Validation**: Invalid certificates blocked

---

### 6. Cookies

The App manages cookies as follows when browsing websites:

- **Session Cookies**: Allowed (required for website functionality)
- **Third-Party Cookies**: Blocked
- **Cookie Deletion**: On app exit or manual deletion

---

### 7. Auto-Delete Feature

About the App's signature "Auto-Delete" feature:

- **Deletion Trigger**: After 90 days of app inactivity
- **Deletion Target**: All downloaded files, browsing history, bookmarks, settings
- **Notification**: Push notification 7 days before deletion
- **Recovery**: No recovery possible after deletion

This feature is designed to prevent digital legacy in case of sudden accidents or illness.

---

### 8. User Rights

#### 8.1 Right to Delete
Users can delete data at any time by:

1. **In-App Deletion**: "Delete All Files" in Settings
2. **Uninstall**: Delete the app from iPhone

#### 8.2 Data Portability
Currently, we do not provide data export functionality (under consideration for Phase 2).

---

### 9. Children's Privacy

The App is not directed to children under 13.
Even if used by children under 13, no personal information is collected.

---

### 10. Changes to Privacy Policy

This Privacy Policy may be updated as needed.
Significant changes will be notified via in-app notification or App Store description.

---

### 11. Contact Us

For privacy-related questions:

- **Email**: support@vanishbrowser.com (to be added)
- **GitHub**: https://github.com/YOUR_USERNAME/vanish-browser/issues

---

### 12. Governing Law

This Privacy Policy is governed by the laws of Japan.

---

## App Store Privacy Nutrition Label

### Data Collection Summary

```
データ収集 / Data Collection: なし / None

データの種類 / Data Types:
- 収集するデータ / Data Collected: なし / None
- トラッキング / Tracking: なし / None
- データリンク / Data Linked to You: なし / None
```

---

## オープンソース化について / About Open Source

当アプリは、透明性を高めるため、**Phase 2以降でのオープンソース化を検討**しています。

ソースコードが公開されることで、以下のメリットがあります：

- ✅ プライバシー保護の実装を第三者が検証可能
- ✅ セキュリティ監査が容易
- ✅ コミュニティによる改善提案

---

We are considering **open-sourcing the app in Phase 2** to increase transparency.

Benefits of open-sourcing:

- ✅ Third-party verification of privacy implementation
- ✅ Easier security audits
- ✅ Community-driven improvements

---

**このプライバシーポリシーは、Vanish Browserのコアコンセプトである「完全なプライバシー保護」を反映しています。**

**This Privacy Policy reflects Vanish Browser's core concept of "complete privacy protection."**
