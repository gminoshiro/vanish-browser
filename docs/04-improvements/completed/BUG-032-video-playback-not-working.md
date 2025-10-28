# BUG-032: 動画再生できなくなっている

🔴 P0 Critical | ✅ 修正完了

（注：元々BUG-013として記録されていたが、BUG-013-image-download-no-extension.mdと重複していたためBUG-032に変更）

---

## 問題

動画をクリックしても再生されない。BUG-007またはBUG-008の対応時に発生した可能性が高い。

---

## 原因

BrowserViewModel.swiftのJavaScriptコードで、動画クリック時に`videoClicked`メッセージを送信し、`ShowCustomVideoPlayer`通知でカスタムビデオプレーヤーを表示しているが、動画要素に`vanishApproved`フラグが設定されていないため、再生が`play`イベントリスナーによってブロックされていた。

### 問題のコード構造

1. **JavaScript側** (BrowserViewModel.swift:258-263)
```javascript
video.addEventListener('play', function(e) {
    if (!video.dataset.vanishApproved) {
        e.preventDefault();
        video.pause();
    }
}, true);
```

2. **Swift側** (BrowserView.swift:619-632 - 修正前)
```swift
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("ShowCustomVideoPlayer"),
    ...
) { notification in
    customVideoURL = url
    customVideoFileName = fileName
    showCustomVideoPlayer = true
    // vanishApprovedフラグが設定されていない！
}
```

---

## 実装内容

`ShowCustomVideoPlayer`通知ハンドラーで、動画要素に`vanishApproved`フラグを設定するJavaScriptを実行するように修正しました。

### 変更点

**BrowserView.swift** (lines 619-643)

修正後:
```swift
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("ShowCustomVideoPlayer"),
    object: nil,
    queue: .main
) { notification in
    if let userInfo = notification.userInfo,
       let url = userInfo["url"] as? URL,
       let fileName = userInfo["fileName"] as? String {
        customVideoURL = url
        customVideoFileName = fileName
        showCustomVideoPlayer = true

        // 動画に承認フラグをセット
        let script = """
        (function() {
            const videos = document.querySelectorAll('video');
            videos.forEach(function(video) {
                video.dataset.vanishApproved = 'true';
            });
        })();
        """
        viewModel.webView.evaluateJavaScript(script, completionHandler: nil)
    }
}
```

### 効果

- 動画クリック時にカスタムビデオプレーヤーが正常に表示され、再生可能になる
- 既存の「再生」ボタンと同じロジックを適用することで一貫性を保つ

---

## テスト方法

1. Safariで動画があるページを開く
2. 動画のカスタムプレーヤー（再生ボタン）をクリック
3. CustomVideoPlayerViewが表示され、動画が再生されることを確認

---

## 関連ファイル

- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift)
- [BrowserViewModel.swift](../../VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift)
- [CustomVideoPlayerView.swift](../../VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift)
