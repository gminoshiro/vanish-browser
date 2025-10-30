# BUG-040: ファーストビューでツールバーが非表示

**作成日**: 2025-10-29
**ステータス**: 🔴 対応中
**優先度**: Critical（App Store リジェクト対応）

---

## App Store リジェクト理由

**Guideline 4.0 - Design**

> Parts of the app's user interface were crowded, laid out, or displayed in a way that made it difficult to use the app when reviewed on iPad Air (5th generation) running iPadOS 26.0.1.
>
> Specifically, the top and bottom bar were cropped.

**審査環境:**
- デバイス: iPad Air (5th generation)
- OS: iPadOS 26.0.1
- バージョン: 1.0
- Submission ID: 9f477c31-9621-4e18-be1d-c846a6b206e8
- Review date: October 29, 2025

---

## 問題

### 現状の動作
- ブラウザ初期表示時、URLバー・ツールバーが非表示
- ユーザーがタップして初めて表示される
- iPadでは画面が広いため、ツールバーがどこにあるか分かりづらい

### 審査での指摘
- トップバー（URLバー）とボトムバー（ツールバー）が見切れている
- iPadでの使用が困難

---

## 期待される動作

### 修正後
1. **初期表示**: URLバー・ツールバーを表示状態でスタート
2. **タップ操作**: タップで表示/非表示を切り替え可能
3. **iPad対応**: 画面サイズに応じたレイアウト調整

---

## 修正方針

### 1. BrowserView.swift の修正

**現状:**
```swift
@State private var showToolbar = false  // 初期状態: 非表示
```

**修正後:**
```swift
@State private var showToolbar = true   // 初期状態: 表示
```

### 2. CustomVideoPlayerView.swift の修正（動画プレーヤー）

**現状:**
```swift
@State private var showToolbar = false  // 初期状態: 非表示
```

**修正後:**
```swift
@State private var showToolbar = true   // 初期状態: 表示
```

### 3. FileViewerView.swift の修正（画像ビューアー）

**現状:**
```swift
@State private var showToolbar = false  // 初期状態: 非表示
```

**修正後:**
```swift
@State private var showToolbar = true   // 初期状態: 表示
```

### 4. iPad対応の改善（オプション）

- Safe Area対応の確認
- iPad専用レイアウト調整
- デバイスサイズに応じたツールバー高さ調整

---

## 影響範囲

### 修正対象ファイル
- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift)
- [CustomVideoPlayerView.swift](../../VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift)
- [FileViewerView.swift](../../VanishBrowser/VanishBrowser/Views/FileViewerView.swift)

### テスト必要デバイス
- ✅ iPhone 15/16 (確認済み)
- ⚠️ iPad Air (5th generation) - iPadOS 26.0.1
- ⚠️ iPad Pro
- ⚠️ iPad mini

---

## 修正内容

### 修正1: BrowserView.swift

変更箇所: 初期状態を表示に変更

```swift
// 修正前
@State private var showToolbar = false

// 修正後
@State private var showToolbar = true
```

### 修正2: CustomVideoPlayerView.swift

変更箇所: 初期状態を表示に変更

```swift
// 修正前
@State private var showToolbar = false

// 修正後
@State private var showToolbar = true
```

### 修正3: FileViewerView.swift

変更箇所: 初期状態を表示に変更

```swift
// 修正前
@State private var showToolbar = false

// 修正後
@State private var showToolbar = true
```

---

## 動作確認

### 確認項目
- [ ] ブラウザ起動時、URLバー・ツールバーが表示されている
- [ ] タップでツールバーを非表示にできる
- [ ] 再度タップで表示に戻る
- [ ] iPad Air (5th generation) で正常に表示される
- [ ] iPhone 15/16 でも正常に動作する
- [ ] 動画プレーヤーでツールバーが表示される
- [ ] 画像ビューアーでツールバーが表示される

---

## 関連チケット

- [BUG-036](completed/BUG-036-custom-player-cutoff-iphone16.md) - iPhone 16でのプレーヤー見切れ
- [BUG-023](completed/BUG-023-toolbar-cutoff-iphone16.md) - ツールバー見切れ

---

**最終更新**: 2025-10-29
