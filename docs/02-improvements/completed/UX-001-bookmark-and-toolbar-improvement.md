# UX-001: ブックマーク機能とツールバーのUX改善

🟡 P2 Medium | ✅ 実装済み

---

## 問題

### 1. ブックマーク機能のUX問題

- **アイコン色の不統一**: ブックマークアイコンだけ黒色（他はブルーまたはプライマリカラー）
- **操作フローが不自然**: アイコンタップでON/OFF切り替えのみ
  - Safari/Alohaのように、タップで「ブックマーク一覧→編集・削除」ができない
- **追加導線が不明確**: ブックマーク追加の方法が分かりにくい
- **フォルダ選択不可**: ダウンロード時のようにフォルダ選択ができない

### 2. 下部ツールバーのレイアウト問題

- **動的にアイコンが増減**: 動画検出時にDLボタンが追加され、レイアウト崩れ
- **アイコンが多すぎる**: 6-7個のアイコンが横並びで窮屈

### 3. 自動削除機能の重複

- **設定が2箇所に存在**:
  - ツールバーのゴミ箱アイコン → `showAutoDeleteSettings`
  - 設定画面内 → 自動削除設定セクション
- **UXが混乱**: どちらを使えば良いか分からない
- **バグリスク**: 2箇所で同じ機能を管理すると不整合が起きやすい

---

## 改善案

### 1. ブックマーク機能の改善

#### ✅ アイコン色の統一

```swift
// Before (268-271行目)
Image(systemName: isBookmarked ? "book.fill" : "book")
    .foregroundColor(isBookmarked ? .blue : .primary)  // .primary = 黒

// After
Image(systemName: isBookmarked ? "book.fill" : "book")
    .foregroundColor(isBookmarked ? .blue : .blue)  // 常にブルー
```

#### ✅ Safari/Aloha風の操作フロー

**現在**:
- タップ → ブックマークON/OFF切り替え

**改善後**:
- タップ → ブックマーク一覧画面を表示
  - ダウンロード一覧と同じUI
  - 編集・削除可能
  - フォルダ表示

#### ✅ ブックマーク追加導線の追加

**方法1: 共有アイコンの下に追加** (推奨)

```swift
// 三点リーダメニュー内に追加
Menu {
    // ... 既存項目 ...
    
    Divider()
    
    Button(action: {
        showBookmarkFolderSelection = true
    }) {
        Label("ブックマークに追加", systemImage: "book.badge.plus")
    }
    
    // ... 設定 ...
}
```

**方法2: 長押しでブックマーク追加**

```swift
.contextMenu {
    Button("ブックマークに追加") {
        showBookmarkFolderSelection = true
    }
}
```

#### ✅ フォルダ選択機能

```swift
// ダウンロード時と同じUI
.sheet(isPresented: $showBookmarkFolderSelection) {
    BookmarkFolderSelectionView(
        title: viewModel.currentTitle ?? "",
        url: viewModel.currentURL ?? "",
        onSave: { folder in
            BookmarkService.shared.addBookmark(...)
        }
    )
}
```

---

### 2. 下部ツールバーのレイアウト改善

#### ❌ 動的にアイコンを追加しない

**現在の問題箇所（231-244行目）**:
```swift
// 動画再生中はDLボタンを左端に追加
if viewModel.hasVideo {
    Button(action: { ... }) {
        Image(systemName: "arrow.down.circle.fill")
    }
}
```

**改善策**: 
- 動画DLボタンは**オーバーレイのみ**に表示（183-213行目は維持）
- ツールバーには追加しない

#### ✅ ツールバーを固定レイアウトに

```swift
HStack(spacing: 8) {
    // 戻る
    Button(action: { viewModel.goBack() }) { ... }
    
    // 進む
    Button(action: { viewModel.goForward() }) { ... }
    
    // 更新
    Button(action: { viewModel.reload() }) { ... }
    
    Spacer()
    
    // ブックマーク一覧（常にブルー）
    Button(action: { showBookmarks = true }) {
        Image(systemName: "book")
            .foregroundColor(.blue)
    }
    
    // 履歴
    Button(action: { showBrowsingHistory = true }) { ... }
    
    // ダウンロード
    Button(action: { showDownloads = true }) { ... }
    
    // メニュー（三点リーダ）
    Menu { ... } label: { ... }
}
```

**アイコン数**: 7個固定（動的増減なし）

---

### 3. 自動削除機能の重複解消

#### ❌ ツールバーのゴミ箱アイコンを削除

**削除箇所（287-293行目）**:
```swift
Button(action: {
    showAutoDeleteSettings = true
}) {
    Image(systemName: "trash")
        .foregroundColor(.red)
}
```

#### ✅ 設定画面のみに統一

**理由**:
1. **コンセプトに合致**: Vanish Browserのコア機能なので、設定画面にあるべき
2. **誤操作防止**: ツールバーから削除設定を変更するのは危険
3. **UX整理**: 設定は設定画面に集約

**代替案（必要なら）**:
- 三点リーダメニュー内に「自動削除設定」を追加

```swift
Menu {
    // ... 既存項目 ...
    
    Divider()
    
    Button(action: {
        showAutoDeleteSettings = true
    }) {
        Label("自動削除設定", systemImage: "trash.clock")
    }
    
    Button(action: {
        showSettings = true
    }) {
        Label("設定", systemImage: "gearshape")
    }
}
```

---

## 実装ステップ

### Phase 1: ブックマーク機能改善

1. ✅ アイコン色を常にブルーに変更
2. ✅ `showBookmarks`シートを追加
3. ✅ ブックマーク一覧画面を作成（DownloadsViewと同じUI）
4. ✅ 三点リーダメニューに「ブックマークに追加」を追加
5. ✅ フォルダ選択UI追加

**開発期間**: 2-3日

---

### Phase 2: ツールバーレイアウト改善

1. ✅ 動画DLボタンをツールバーから削除（オーバーレイのみ）
2. ✅ ゴミ箱アイコンを削除
3. ✅ ブックマークアイコンの動作を変更（タップで一覧表示）
4. ✅ アイコン数を7個固定に

**開発期間**: 1日

---

### Phase 3: 自動削除設定の整理

1. ✅ `showAutoDeleteSettings`シートを削除
2. ✅ 設定画面のみに統一
3. ✅ （オプション）三点リーダに「自動削除設定」追加

**開発期間**: 0.5日

---

## 完成後のツールバー

```
[←] [→] [🔄]  [Spacer]  [📖] [🕐] [⬇️] [⋯]
```

- `[←]` 戻る
- `[→]` 進む
- `[🔄]` 更新
- `[📖]` ブックマーク一覧
- `[🕐]` 履歴
- `[⬇️]` ダウンロード
- `[⋯]` メニュー
  - ページ内検索
  - リーダーモード
  - デスクトップサイト
  - Cookie管理
  - **ブックマークに追加** ← New!
  - 自動削除設定 ← New!（オプション）
  - 設定

---

## 関連ファイル

- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift)
- [BookmarkService.swift](../../VanishBrowser/VanishBrowser/Services/BookmarkService.swift)

---

## 作成日

2025-10-19
