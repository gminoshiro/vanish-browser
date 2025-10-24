# BUG-034: プライベートタブ中にタブボタンを押すとトグルが通常になる

🟡 P2 Medium | ✅ 修正完了

---

## 問題

プライベートタブで閲覧中にタブボタンを押すと、タブ管理画面のトグルが「通常」になっており、プライベートタブが表示されない。

### 期待動作
- プライベートタブ閲覧中にタブボタンを押す
- タブ管理画面のトグルが「プライベート」になっている
- プライベートタブが表示される

---

## 原因

[TabManagerView.swift:13](../../VanishBrowser/VanishBrowser/Views/TabManagerView.swift#L13)で`selectedMode`が常に`.normal`で初期化されていた。

---

## 修正内容

**[TabManagerView.swift:20-25](../../VanishBrowser/VanishBrowser/Views/TabManagerView.swift#L20-L25)**
- `init(tabManager:)`を追加
- 現在のタブの`isPrivate`を確認して初期値を設定
- `isPrivate=true`なら`.private_`、`false`なら`.normal`

---

## テスト項目

- [ ] プライベートタブ閲覧中にタブボタンを押すとトグルが「プライベート」になることを確認
- [ ] 通常タブ閲覧中にタブボタンを押すとトグルが「通常」になることを確認
- [ ] トグル切り替え後も正常に動作することを確認

---

## 関連ファイル

- [TabManagerView.swift](../../VanishBrowser/VanishBrowser/Views/TabManagerView.swift)
- [TabManager.swift](../../VanishBrowser/VanishBrowser/ViewModels/TabManager.swift)
