# BUG-040: iPadでツールバー見切れ

**作成日**: 2025-10-29
**ステータス**: ✅ 修正完了
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

### 根本原因
1. URLバー・ツールバーのpaddingがSafe Areaを考慮していない
2. iPadで画面端まで広がり、見切れる
3. タップでバー切り替えの仕様が審査で問題視される可能性

---

## 修正内容

### 1. iPad対応のpadding調整

**BrowserView.swift - URLバー:**
```swift
// 修正前
.padding()

// 修正後
.padding(.horizontal)
.padding(.top, 8)
.padding(.bottom, 8)
```

**BrowserView.swift - ツールバー:**
```swift
// 修正前
.padding(.horizontal, 8)
.padding(.vertical, 6)

// 修正後
.padding(.horizontal, 12)
.padding(.top, 6)
.padding(.bottom, 8)
```

**FileViewerView.swift - ツールバー:**
```swift
// 修正前
.padding()

// 修正後
.padding(.horizontal)
.padding(.top, 12)
.padding(.bottom, 8)
```

### 2. スクロール連動バー表示

**iPad:**
- バーを常に表示（スクロールで非表示にしない）
- 画面が大きいので邪魔にならない

**iPhone:**
- 起動時・ホーム画面：バー表示
- 下スクロール：バー非表示
- 上スクロール：バー表示

**BrowserViewModel.swift:**
```swift
// iPad判定
private var isIPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}

func handleScroll(offset: CGFloat) {
    // iPadの場合はスクロールでバーを隠さない
    if isIPad {
        showToolbars = true
        return
    }

    // iPhone: スクロール連動でバー表示/非表示
    // ...
}
```

### 3. タップ切り替え削除

- ホーム画面タップでのバー切り替えを削除
- Safari/Chrome/Alohaと同様のスクロール連動のみ

---

## 動作確認

### iPad
- ✅ 起動時にURLバー・ツールバーが表示
- ✅ スクロールしてもバーが消えない
- ✅ URLバー・ツールバーが画面端で見切れない
- ✅ タップでバーが消えない

### iPhone
- ✅ 起動時にURLバー・ツールバーが表示
- ✅ 下スクロールでバー非表示
- ✅ 上スクロールでバー表示
- ✅ タップでバーが消えない

---

## 影響範囲

### 修正ファイル
- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift) - padding調整、タップ切り替え削除
- [FileViewerView.swift](../../VanishBrowser/VanishBrowser/Views/FileViewerView.swift) - padding調整
- [BrowserViewModel.swift](../../VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift) - iPad判定追加

---

## 関連チケット

- [BUG-036](completed/BUG-036-custom-player-cutoff-iphone16.md) - iPhone 16でのプレーヤー見切れ
- [BUG-023](completed/BUG-023-toolbar-cutoff-iphone16.md) - ツールバー見切れ

---

## コミット

- `ab49de7` - fix: BUG-040 iPad対応とスクロール連動バー表示

---

**最終更新**: 2025-10-30
