# BUG-033: プライベートブラウザの閲覧履歴が保存される

🔴 P0 Critical | ✅ 修正完了

---

## 問題

プライベートブラウザで閲覧した履歴が、閲覧履歴画面で確認できてしまう。

### 期待動作
- プライベートタブでの閲覧は履歴に**一切残さない**
- 通常タブのみ履歴に記録

---

## 原因

[BrowserViewModel.swift:764-770](../../VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift#L764-L770)で履歴保存時にタブのisPrivateフラグをチェックしていなかった。

---

## 修正内容

1. **[BrowsingHistory.swift:37-41](../../VanishBrowser/VanishBrowser/Models/BrowsingHistory.swift#L37-L41)**
   - `addToHistory`メソッドに`isPrivate`パラメータを追加
   - `isPrivate=true`の場合は早期returnで履歴保存をスキップ

2. **[BrowserViewModel.swift:70](../../VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift#L70)**
   - `tabManager`への参照を追加

3. **[BrowserViewModel.swift:770-771](../../VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift#L770-L771)**
   - 履歴保存時に`tabManager.currentTab?.isPrivate`を取得
   - `BrowsingHistoryManager.shared.addToHistory`に`isPrivate`フラグを渡す

4. **[BrowserView.swift:521-522](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift#L521-L522)**
   - `onAppear`でviewModelにtabManagerを設定

---

## テスト項目

- [ ] プライベートタブで閲覧した履歴が保存されないことを確認
- [ ] 通常タブの履歴は正常に保存されることを確認
- [ ] タブ切り替え時に正しくisPrivateが反映されることを確認

---

## 関連ファイル

- [BrowsingHistory.swift](../../VanishBrowser/VanishBrowser/Models/BrowsingHistory.swift)
- [BrowserViewModel.swift](../../VanishBrowser/VanishBrowser/ViewModels/BrowserViewModel.swift)
- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift)
