# BUG-011: 自動削除と削除対象が紐づいていない

🟠 P1 High | 📝 未着手

---

## 問題

自動削除タイミングを設定しても、削除対象のトグル（閲覧履歴、ダウンロード、ブックマーク）が反映されない。

### 確認された問題
1. 閲覧履歴ONでも削除されない
2. すべてOFFでも何か削除される（ファイルとブックマーク？）
3. トグルの状態が無視されている

---

## 期待される動作

### 1. トグルに応じた削除
- 閲覧履歴ON → 閲覧履歴を削除
- ダウンロードON → ダウンロードファイルを削除
- ブックマークON → ブックマークを削除

### 2. すべてOFFの場合
- 警告を表示：「削除対象が選択されていません」
- 自動削除を実行しない

---

## 修正内容

`performAutoDelete()`は既にトグルを確認しているが、呼び出し元が正しく動作していない可能性。
トグルの状態確認とログ出力を強化。

---

## 関連ファイル

- [AutoDeleteService.swift](../../VanishBrowser/VanishBrowser/Services/AutoDeleteService.swift) (180-186行目: performAutoDelete)
- [SettingsView.swift](../../VanishBrowser/VanishBrowser/Views/SettingsView.swift)
