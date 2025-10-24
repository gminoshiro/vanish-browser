# BUG-035: 生体認証失敗時にパスコード入力できない

🔴 P0 Critical | ✅ 修正完了

---

## 問題

生体認証が失敗した場合、パスコード入力画面が表示されず、アプリに入れなくなる。

### 期待動作
- 生体認証ONの場合は必ずパスコード設定が必要
- 生体認証失敗時にパスコード入力にフォールバック
- 認証機能自体は任意（ON/OFF可能）

---

## 修正内容

### 1. SettingsView.swift
**[SettingsView.swift:46-88](../../VanishBrowser/VanishBrowser/Views/SettingsView.swift#L46-L88)**
- **認証ONにした時にパスコード未設定なら自動的に設定画面を表示**
- パスコード設定を生体認証使用時も必須に変更
- パスコード未設定時は「パスコードを設定（必須）」ボタンを表示
- 生体認証トグルはパスコード設定済みの場合のみ有効化
- パスコードクリア時は生体認証も自動的にOFFに

### 2. AuthenticationView.swift
**[AuthenticationView.swift:36-48](../../VanishBrowser/VanishBrowser/Views/AuthenticationView.swift#L36-L48)**
- 生体認証失敗時（`authError != nil`）にパスコード入力画面を表示
- エラーメッセージをパスコード設定状況に応じて変更

**[AuthenticationView.swift:99-116](../../VanishBrowser/VanishBrowser/Views/AuthenticationView.swift#L99-L116)**
- 生体認証失敗時のエラーメッセージを改善
- パスコード未設定時: "認証に失敗しました。設定でパスコードを設定してください。"
- パスコード設定済み時: "パスコードを入力してください"

---

## テスト項目

- [ ] パスコード未設定時に生体認証トグルが無効化されることを確認
- [ ] パスコード設定後に生体認証トグルが有効化されることを確認
- [ ] 生体認証失敗時にパスコード入力画面が表示されることを確認
- [ ] パスコード入力でアプリに入れることを確認
- [ ] パスコードクリア時に生体認証がOFFになることを確認

---

## 関連ファイル

- [AuthenticationView.swift](../../VanishBrowser/VanishBrowser/Views/AuthenticationView.swift)
- [SettingsView.swift](../../VanishBrowser/VanishBrowser/Views/SettingsView.swift)
- [BiometricAuthService.swift](../../VanishBrowser/VanishBrowser/Services/BiometricAuthService.swift)
