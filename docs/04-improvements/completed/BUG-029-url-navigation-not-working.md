# BUG-029: URL入力・検索で画面遷移しない

🔴 P0 Critical | ✅ 修正完了

---

## 問題

URLバーにURLを入力したり、検索語を入力しても、ログ的には遷移しているが、UI的には画面が更新されない。

---

## ログ

```
Adding '_UIReparentingView' as a subview of UIHostingController.view is not supported
and may result in a broken view hierarchy.
```

---

## 原因

`UIViewRepresentable`の`updateUIView`が何もしていなかった。

タブ切り替え時に`viewModel.switchWebView(to:)`で新しいWebViewインスタンスに切り替わるが、`UIViewRepresentable`は**古いWebViewを表示し続ける**ため、UIが更新されなかった。

### 問題のコード（BrowserView.swift:818-820）

```swift
func updateUIView(_ uiView: WKWebView, context: Context) {
    // 更新は不要  ← これが問題！
}
```

`uiView`（古いWebView）と`viewModel.webView`（新しいWebView）が異なるインスタンスになっているのに、UIを更新していなかった。

---

## 修正内容

`updateUIView`で、WebViewインスタンスが変わったことを検出し、親ビューから古いWebViewを削除して新しいWebViewを追加：

```swift
func updateUIView(_ uiView: WKWebView, context: Context) {
    // タブ切り替え時にWebViewインスタンスが変わった場合、
    // UIViewRepresentableは古いWebViewを表示し続けるため、
    // 新しいWebViewに置き換える必要がある
    if uiView !== viewModel.webView {
        // WebViewの親ビューを取得して、新しいWebViewに置き換え
        if let superview = uiView.superview {
            uiView.removeFromSuperview()
            superview.addSubview(viewModel.webView)
            viewModel.webView.frame = superview.bounds
            viewModel.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            viewModel.webView.uiDelegate = context.coordinator
            viewModel.webView.allowsLinkPreview = false
        }
    }
}
```

### キーポイント

- `!==`: インスタンスの参照比較（同一オブジェクトか？）
- `removeFromSuperview()`: 古いWebViewを削除
- `addSubview()`: 新しいWebViewを追加
- `autoresizingMask`: WebViewが親ビューのサイズに追従

---

## テスト方法

1. URLバーに`google.com`を入力 → Googleが表示される
2. 検索語`test`を入力 → 検索結果が表示される
3. タブを切り替える → 各タブの内容が正しく表示される
4. 戻る/進むボタン → 履歴が正しく動作

---

## 関連ファイル

- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift#L818-L833)

---

## 作成日

2025-10-20
