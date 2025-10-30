# BUG-041: 動画再生中にタップでコントロールバーが出ない

**ステータス**: ✅ 修正完了
**優先度**: High
**発見日**: 2025-10-30
**担当**: Claude

---

## 問題

### 現象
- ダウンロード済み動画再生中、コントロールバーが非表示の状態でタップしても表示されないことがある
- 最初の1回はタップで表示されるが、その後タップしても表示されなくなる
- 期待動作：
  - バー非表示中にタップ → バー表示
  - バー表示中にタップ → バー非表示
  - 3秒後の自動非表示

### 再現手順
1. ダウンロード済み動画を開く
2. 動画再生開始（コントロールバー表示）
3. 3秒待ってコントロールバーが自動で非表示になる
4. 画面をタップ → 1回目は表示される
5. 再度タップ → 2回目以降は表示されない

### 影響範囲
- CustomVideoPlayerView.swift
- ユーザーが動画操作できなくなる（重大）

---

## 原因分析

### 原因1: ZStackの重なり順とタップジェスチャーの競合
- タップジェスチャーが動画プレーヤー（CustomAVPlayerView）にのみ配置されていた
- コントロール表示時、ボタンやスライダーが上に重なり、タップを受け取ってしまう
- 動画プレーヤーの`.onTapGesture`まで届かない

### 原因2: 自動非表示Taskの管理不足
デバッグログから判明：
```
🔍 toggleControls実行後: showControls = true
🔍 scheduleHideControls呼び出し  ← 3秒タイマー開始
🔍 タップ検知: showControls = true  ← ユーザーが再度タップ
🔍 toggleControls実行後: showControls = false  ← falseに変更
🔍 3秒経過: 自動非表示実行  ← でもタイマーはまだ動いている
🔍 自動非表示完了: showControls = false  ← 強制的にfalse
```

**問題点**：
1. `showControls = true`にした時、`scheduleHideControls()`で3秒タイマー開始
2. ユーザーが手動で`showControls = false`にしても、タイマーはキャンセルされない
3. 3秒後にタイマーが発火し、強制的に`showControls = false`を実行
4. この時点でUIが壊れ、以降タップしても表示されなくなる

### 原因3: withAnimation内でのtoggle()
`withAnimation { showControls.toggle() }`が正しく動作しないケースがある

---

## 修正内容

### 修正1: タップジェスチャーをZStack全体に移動

#### Before (CustomVideoPlayerView.swift:45-49)
```swift
CustomAVPlayerView(player: playerViewModel.player)
    .ignoresSafeArea()
    .onTapGesture {
        toggleControls()
    }
```

#### After (CustomVideoPlayerView.swift:45-46, 210-213)
```swift
// 動画プレーヤーからタップジェスチャー削除
CustomAVPlayerView(player: playerViewModel.player)
    .ignoresSafeArea()

// ... (中略)

// ZStack全体にタップジェスチャー配置
}
.contentShape(Rectangle())
.onTapGesture {
    toggleControls()
}
```

### 修正2: toggleControls()でTaskをキャンセル

#### Before (CustomVideoPlayerView.swift:255-262)
```swift
private func toggleControls() {
    withAnimation {
        showControls.toggle()
    }
    if showControls {
        scheduleHideControls()
    }
}
```

#### After (CustomVideoPlayerView.swift:254-264)
```swift
private func toggleControls() {
    let newValue = !showControls
    withAnimation {
        showControls = newValue
    }
    if newValue {
        scheduleHideControls()
    } else {
        hideControlsTask?.cancel()  // ← 非表示時はTaskキャンセル
    }
}
```

**ポイント**：
- `.contentShape(Rectangle())`: ZStack全体（透明部分含む）をタップ可能に
- `let newValue = !showControls`: toggle()を使わず明示的に値を設定
- `hideControlsTask?.cancel()`: 非表示にする時は必ず自動非表示タイマーをキャンセル

---

## 動作確認項目

- [x] バー非表示時に画面タップでバーが表示される
- [x] バー表示時に画面タップでバーが非表示になる
- [x] 3秒後の自動非表示が正常に動作
- [x] ×ボタン、再生ボタン、シークバーなどのコントロールが正常に動作
- [x] 共有ボタン（DL済み動画）が正常に動作
- [x] ダウンロードボタン（DL前動画）が正常に動作
- [x] 繰り返しタップしても正常に表示/非表示が切り替わる

---

## 関連ファイル
- [CustomVideoPlayerView.swift](VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift)

---

## コミット
- コミット: `fix: BUG-041 動画プレーヤーのタップ処理を修正`
