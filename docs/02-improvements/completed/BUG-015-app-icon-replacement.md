# BUG-015: アプリアイコン差し替え

🟡 P2 Low | ✅ 修正完了

---

## 問題

新しいアイコン画像を用意したので、アプリアイコンを差し替えたい。

---

## アイコンの配置場所

```
/Users/genfutoshi/vanish-browser/VanishBrowser/VanishBrowser/Assets.xcassets/AppIcon.appiconset/
```

### 現在のファイル構成

```
AppIcon.appiconset/
├── Contents.json      # アイコン設定ファイル
└── icon_1024.png      # 現在のアイコン（1024x1024）
```

---

## 差し替え手順

### 方法1: Xcode経由（推奨）

1. Xcodeでプロジェクトを開く
2. 左ペインで `Assets.xcassets` を選択
3. `AppIcon` をクリック
4. 新しいアイコン画像をドラッグ&ドロップ
5. Xcodeが自動的に必要なサイズを生成

### 方法2: 手動配置

1. 以下のディレクトリに新しいアイコンを配置:
   ```
   /Users/genfutoshi/vanish-browser/VanishBrowser/VanishBrowser/Assets.xcassets/AppIcon.appiconset/
   ```

2. 必要なアイコンサイズ（iOS）:
   - **1024x1024**: App Store用（必須）
   - 他のサイズはXcodeが自動生成可能

3. `Contents.json` の編集は通常不要（Xcodeが自動更新）

---

## 注意事項

- PNG形式を使用すること
- 透明度（アルファチャンネル）は使用不可
- 1024x1024サイズは必須
- ファイル名は `icon_1024.png` または任意の名前でOK

---

## 実装内容

新しいアイコン画像 `Gemini_Generated_Image_h5k83vh5k83vh5k8.png` を配置し、`Contents.json` を更新しました。

**変更ファイル**:
- `Assets.xcassets/AppIcon.appiconset/Contents.json`
- `Assets.xcassets/AppIcon.appiconset/Gemini_Generated_Image_h5k83vh5k83vh5k8.png` (新規追加)

---

## 作成日

2025-10-17

## 完了日

2025-10-17
