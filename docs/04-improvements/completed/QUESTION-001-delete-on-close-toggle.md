# QUESTION-001: 「アプリ終了時に削除」トグルは不要？

⏳ ユーザー確認待ち

---

## 質問

「アプリ終了時に削除」トグルは削除してよいか？

---

## 理由

自動削除タイミングで「アプリ終了時」を選択できるため、トグルは冗長。

---

## 現在の仕様

- 自動削除タイミング: 無効、アプリ終了時、5分後、10分後...
- 「アプリ終了時に削除」トグル: ON/OFF

→ 両方で「アプリ終了時」を設定可能で混乱する

---

## 提案

「アプリ終了時に削除」トグルを削除し、自動削除タイミングの選択肢に統一する。

---

## 関連ファイル

- [AutoDeleteService.swift](../../VanishBrowser/VanishBrowser/Services/AutoDeleteService.swift)
- [SettingsView.swift](../../VanishBrowser/VanishBrowser/Views/SettingsView.swift)
