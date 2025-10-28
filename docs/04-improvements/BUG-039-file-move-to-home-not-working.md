# BUG-039: ファイル移動でホームへ移動できない

**作成日**: 2025-10-28
**ステータス**: ✅ 修正完了
**優先度**: Medium

---

## 問題

ファイル移動画面で「ホーム」を選択しても、UI上でファイルがホームに移動したように表示されない。
ファイルシステム上は移動成功しているが、Core Dataの更新が不完全でUI反映されていなかった。

## 原因

1. **Core Dataのfolderプロパティ未更新**: `DownloadService.moveFile()`で`file.filePath`のみ更新し、`file.folder`を更新していなかった
2. **UI更新タイミング**: Core Data保存後すぐにfetchしても変更が反映されない
3. **シート閉じるタイミング**: `onSelect()`→`dismiss()`の順で実行され、UI更新が見えなかった

## 修正内容

### 1. Core Dataのfolder更新 ([DownloadService.swift:464](../../VanishBrowser/VanishBrowser/Services/DownloadService.swift#L464))
```swift
file.filePath = getRelativePath(from: newURL.path)
file.folder = folderName.isEmpty ? nil : folderName  // 追加
```

### 2. processPendingChanges追加 ([DownloadService.swift:467-471](../../VanishBrowser/VanishBrowser/Services/DownloadService.swift#L467-471))
```swift
viewContext.processPendingChanges()
try viewContext.save()
viewContext.processPendingChanges()
```

### 3. ViewModel強制再描画 ([DownloadListView.swift:390](../../VanishBrowser/VanishBrowser/Views/DownloadListView.swift#L390))
```swift
viewModel.refresh()  // objectWillChange.send()
loadDownloads()
```

### 4. シート閉じる順序変更 ([DownloadListView.swift:780-783](../../VanishBrowser/VanishBrowser/Views/DownloadListView.swift#L780-783))
```swift
dismiss()
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    onSelect("")
}
```

## 動作確認

- ✅ フォルダ内ファイル→ホームへ移動
- ✅ 移動直後のUI更新
- ✅ フォルダ→フォルダ移動も正常動作

## 関連ファイル

- [DownloadListView.swift](../../VanishBrowser/VanishBrowser/Views/DownloadListView.swift)
- [DownloadService.swift](../../VanishBrowser/VanishBrowser/Services/DownloadService.swift)

## コミット

- `6569935` - fix: BUG-039 ファイル移動後のUI更新問題を修正

---

**最終更新**: 2025-10-28
