# 環境構築手順

**最終更新**: 2025年10月8日

---

## 💻 必要な環境

| 項目 | 要件 | 推奨 |
|------|------|------|
| **OS** | macOS 13.0以上 | macOS 14.0以上 |
| **Xcode** | 15.0以上 | 15.4以上 |
| **iOS** | 15.0以上 | 17.0以上 |
| **Apple ID** | 必須（実機テスト時） | - |
| **Apple Developer Program** | 任意（TestFlight/リリース時） | 年額¥12,980 |

---

## 🚀 セットアップ手順

### Step 1: リポジトリクローン

```bash
# HTTPSでクローン
git clone https://github.com/YOUR_USERNAME/vanish-browser.git
cd vanish-browser

# または SSH
git clone git@github.com:YOUR_USERNAME/vanish-browser.git
cd vanish-browser
```

**確認**:
```bash
ls -la
# docs/, README.md等が表示されればOK
```

---

### Step 2: Xcodeプロジェクト作成

**Phase 1時点ではまだ未作成**。以下は作成時の手順です。

#### 2-1. Xcodeで新規プロジェクト作成

1. Xcodeを起動
2. `File` → `New` → `Project...`
3. テンプレート選択:
   - **iOS** → **App**
4. プロジェクト設定:
   - **Product Name**: `VanishBrowser`
   - **Team**: （実機テスト時に設定）
   - **Organization Identifier**: `com.vanishbrowser`
   - **Bundle Identifier**: `com.vanishbrowser.VanishBrowser`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `Core Data`
5. 保存先: プロジェクトルート（vanish-browser/）

#### 2-2. ディレクトリ構造作成

```bash
mkdir -p VanishBrowser/{Models,Views,ViewModels,Services,Utilities}
```

#### 2-3. .gitignore作成

```bash
cat > .gitignore <<'EOF'
# Xcode
build/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/
*.xccheckout
*.moved-aside
DerivedData/
*.hmap
*.ipa
*.xcuserstate

# Swift Package Manager
.swiftpm/

# CocoaPods
Pods/

# macOS
.DS_Store

# Secrets
*.pem
*.p12
EOF
```

---

### Step 3: Xcodeプロジェクト初期設定

#### 3-1. Bundle Identifier設定

1. プロジェクトナビゲータで`VanishBrowser`を選択
2. **TARGETS** → **VanishBrowser**
3. **General** タブ
4. **Bundle Identifier**: `com.vanishbrowser.VanishBrowser`

#### 3-2. Deployment Target設定

1. **General** タブ
2. **Minimum Deployments**: `iOS 15.0`

#### 3-3. Team設定（実機テスト時）

1. **Signing & Capabilities** タブ
2. **Team**: Apple IDでログイン
3. **Automatically manage signing**: チェック

---

### Step 4: Capabilities設定

#### 4-1. Face ID / Touch ID

1. **Signing & Capabilities** タブ
2. `+ Capability`をクリック
3. **検索**: `Privacy`
4. 追加不要（Info.plistで設定）

**Info.plist追加**:
```xml
<key>NSFaceIDUsageDescription</key>
<string>アプリを開くためにFace IDを使用します</string>
```

#### 4-2. Background Modes（通知用）

1. `+ Capability` → **Background Modes**
2. チェック:
   - ✅ **Remote notifications**

#### 4-3. File Protection

デフォルトで有効（追加設定不要）

---

### Step 5: Core Dataモデル作成

#### 5-1. .xcdatamodeldファイル作成

1. `File` → `New` → `File...`
2. **Core Data** → **Data Model**
3. 名前: `VanishBrowser.xcdatamodeld`

#### 5-2. エンティティ追加

**DownloadedFile**:
- Attributes:
  - `id`: UUID
  - `fileName`: String
  - `filePath`: String
  - `downloadedAt`: Date
  - `fileSize`: Integer 64
  - `mimeType`: String (Optional)
  - `thumbnailPath`: String (Optional)
  - `isEncrypted`: Boolean

**Bookmark**:
- Attributes:
  - `id`: UUID
  - `title`: String
  - `url`: String
  - `createdAt`: Date
  - `faviconPath`: String (Optional)
  - `folder`: String

**AppSettings**:
- Attributes:
  - `id`: UUID
  - `lastOpenedAt`: Date
  - `autoDeleteDays`: Integer 32
  - `isAuthEnabled`: Boolean
  - `deleteWarningDays`: Integer 32
  - `isDarkModeEnabled`: Boolean (Optional)
  - `defaultSearchEngine`: String

---

### Step 6: 実機ビルド確認

#### 6-1. シミュレータでビルド

1. スキーム選択: `VanishBrowser` → **iPhone 15 Pro**
2. `Cmd + R`でビルド・実行
3. アプリが起動すればOK

#### 6-2. 実機でビルド（任意）

1. iPhoneをMacに接続
2. スキーム選択: `VanishBrowser` → **自分のiPhone**
3. **Team**設定（未設定の場合）
4. `Cmd + R`でビルド
5. iPhone側で「信頼」をタップ
6. アプリが起動すればOK

---

### Step 7: シミュレーター言語設定（多言語対応アプリの場合）

アプリが日本語・英語対応している場合、テスト時に言語を切り替える必要があります。

#### 方法1: Xcodeスキーム設定（推奨）

1. Xcodeツールバーで **VanishBrowser > iPhone 17** の横にある**スキーム名**をクリック
2. **Edit Scheme...** を選択
3. 左側から **Run** を選択
4. **Options** タブをクリック
5. **App Language** を選択:
   - **Japanese（日本語）**: 日本語でテスト
   - **English**: 英語でテスト
   - **System Language**: システム言語に従う（デフォルト）
6. **Close** をクリック
7. `Cmd + R` でビルド・実行

**メリット**: ビルドのたびに自動的に指定言語で起動

#### 方法2: シミュレーター設定（手動）

1. シミュレーターで **Settings** アプリを開く
2. **General** → **Language & Region**
3. **iPhone Language** をタップ
4. 言語を選択（日本語 / English）
5. **Change to 日本語** / **Change to English** をタップ
6. シミュレーターが再起動される

#### 方法3: コマンドライン

```bash
# シミュレーターのデバイスIDを確認
xcrun simctl list devices

# 日本語に変更
DEVICE_ID="<your-device-id>"
xcrun simctl spawn $DEVICE_ID defaults write "Apple Global Domain" AppleLanguages -array ja
xcrun simctl shutdown $DEVICE_ID && xcrun simctl boot $DEVICE_ID

# 英語に変更
xcrun simctl spawn $DEVICE_ID defaults write "Apple Global Domain" AppleLanguages -array en
xcrun simctl shutdown $DEVICE_ID && xcrun simctl boot $DEVICE_ID
```

**推奨**: 方法1（Xcodeスキーム設定）が最も効率的

---

## 🔐 Apple Developer Program登録（リリース時）

### 費用

| 項目 | 金額 |
|------|------|
| **Apple Developer Program** | ¥12,980/年 |
| **支払い方法** | クレジットカード |

### 登録手順

1. [Apple Developer](https://developer.apple.com/)にアクセス
2. 「Join the Apple Developer Program」をクリック
3. Apple IDでログイン
4. 個人情報入力
5. 支払い情報入力
6. 審査待ち（通常1-2日）

### 登録後の設定

1. Xcode → **Preferences** → **Accounts**
2. Apple IDを追加
3. **Download Manual Profiles**

---

## 🛠️ トラブルシューティング

### エラー1: "Failed to prepare device for development"

**原因**: iOSバージョンとXcodeの不一致

**解決策**:
```bash
# Xcodeを最新版にアップデート
# または
# iPhoneを最新iOSにアップデート
```

---

### エラー2: "Signing for "VanishBrowser" requires a development team"

**原因**: Team未設定

**解決策**:
1. **Signing & Capabilities**
2. **Team**: Apple IDを選択
3. 無料アカウントでも実機テスト可能（7日間）

---

### エラー3: "Unable to install "VanishBrowser""

**原因**: iPhone側で信頼されていない

**解決策**:
1. iPhone: **設定** → **一般** → **VPNとデバイス管理**
2. 開発者アプリ → **信頼**

---

### エラー4: Core Dataモデル読み込みエラー

**原因**: .xcdatamodeldファイルが見つからない

**解決策**:
```swift
// ファイル名を確認
let container = NSPersistentContainer(name: "VanishBrowser")  // 正しい名前
```

---

### エラー5: SwiftUI Previewが動かない

**原因**: Xcodeのキャッシュ問題

**解決策**:
```bash
# Xcode再起動
# または
rm -rf ~/Library/Developer/Xcode/DerivedData
```

---

## 🧪 推奨設定

### SwiftLint導入（任意）

**インストール**:
```bash
brew install swiftlint
```

**.swiftlint.yml作成**:
```yaml
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - empty_count
  - explicit_init
line_length: 120
function_body_length: 50
file_length: 400
cyclomatic_complexity: 10
```

**Xcode Build Phaseに追加**:
1. **TARGETS** → **Build Phases**
2. `+` → **New Run Script Phase**
3. スクリプト:
```bash
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed"
fi
```

---

### Cursorの設定（AIコーディング）

**Cursor Rules設定**:
プロジェクトルートに`.cursorrules`ファイル作成:
```
# Vanish Browser プロジェクト

このプロジェクトはiOSアプリ「Vanish Browser」の開発です。

## 技術スタック
- Swift 5.9+
- SwiftUI
- Core Data
- WKWebView

## コーディング規約
- SwiftLint準拠
- コメント率30%以上
- 関数は50行以内

## 参考ドキュメント
- docs/04-design/architecture.md
- docs/03-requirements/functional.md
```

---

## 📋 環境構築チェックリスト

### 初回セットアップ
- [ ] macOS 13.0以上確認
- [ ] Xcode 15.0以上インストール
- [ ] リポジトリクローン
- [ ] Xcodeプロジェクト作成
- [ ] Bundle Identifier設定
- [ ] Deployment Target設定（iOS 15.0）
- [ ] Core Dataモデル作成
- [ ] Info.plist設定（Face ID）

### 実機テスト準備
- [ ] iPhoneをMacに接続
- [ ] Team設定
- [ ] 実機ビルド成功確認
- [ ] iPhone側で「信頼」設定

### リリース準備
- [ ] Apple Developer Program登録
- [ ] 証明書取得
- [ ] Provisioning Profile設定

### 任意設定
- [ ] SwiftLint導入
- [ ] Cursor設定
- [ ] GitHub Actions設定（Phase 2）

---

## 📚 参考リンク

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview)

---

**次のドキュメント**: [テスト計画 (../06-testing/test-plan.md)](../06-testing/test-plan.md)
