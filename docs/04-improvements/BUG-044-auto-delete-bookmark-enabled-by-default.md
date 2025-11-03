# BUG-044: 自動削除設定でブックマークが意図せず削除される

**作成日**: 2025-11-04
**ステータス**: 調査中
**優先度**: Critical
**影響範囲**: 自動削除機能、ブックマーク

---

## 問題

ユーザーがブックマークを追加しても、アプリを再起動すると消えてしまう。

## 現象

1. ブックマークを追加
2. アプリを終了（バックグラウンド）
3. アプリを再起動
4. ブックマークが消えている

## 調査結果

### UserDefaults設定の確認

```
autoDeleteMode = "90日後"
deleteBookmarks = 1  ← ON になっている！
deleteBrowsingHistory = 0
deleteDownloads = 0
deleteTabs = 0
```

### ログ確認

```
📱 設定読み込み: 閲覧履歴=false, DL=false, BM=true, タブ=false
⏰ 最終起動時刻を保存: 2025-11-03 15:08:20 +0000
```

## 原因

過去に設定画面で`deleteBookmarks`をONにした設定がUserDefaultsに保存されたままになっており、自動削除機能が動作している。

**問題点**:
1. AutoDeleteService.swiftの初期値設定が`false`だが、過去の設定が残っている場合はそれが優先される
2. ユーザーが設定を変更したことを忘れている、または意図しない設定になっている可能性がある

## 修正案

### Option 1: 初回起動時のデフォルト値の見直し
- すべての削除設定を`false`にする（現在の仕様）
- ただし、過去の設定が残っている場合は問題が再発する

### Option 2: 設定画面でのWarning表示
- 削除設定がONになっている場合、設定画面で警告を表示
- 「現在、ブックマークの自動削除が有効です」など

### Option 3: マイグレーション処理の追加
- アプリバージョンアップ時に、意図しない削除設定をリセット
- ただし、ユーザーが意図的に設定した場合もリセットされる問題あり

## 再現手順

1. 設定 → 自動削除設定
2. 「ブックマーク」をON
3. 自動削除タイミングを「90日後」に設定
4. ブックマークを追加
5. アプリを終了（90日待つか、システム時刻を変更）
6. アプリを再起動
7. ブックマークが削除されている

## 関連コード

- [AutoDeleteService.swift:107-143](/Users/genfutoshi/vanish-browser/VanishBrowser/VanishBrowser/Services/AutoDeleteService.swift#L107-L143) - 初期値設定
- [AutoDeleteService.swift:243-301](/Users/genfutoshi/vanish-browser/VanishBrowser/VanishBrowser/Services/AutoDeleteService.swift#L243-L301) - 自動削除実行
- [AutoDeleteSettingsView.swift:40-56](/Users/genfutoshi/vanish-browser/VanishBrowser/VanishBrowser/Views/AutoDeleteSettingsView.swift#L40-L56) - 削除対象設定UI

## 次のステップ

1. ユーザーに設定を確認してもらう（設定 → 自動削除設定 → ブックマークがONになっていないか）
2. 設定画面でのWarning表示を追加（Option 2）
3. テストコードで自動削除の動作を検証

## テスト

- [ ] 自動削除設定でブックマークOFF → ブックマークが削除されない
- [ ] 自動削除設定でブックマークON → ブックマークが削除される
- [ ] 設定画面でブックマークONの場合、警告が表示される
