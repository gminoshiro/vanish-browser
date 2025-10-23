# BUG-013: 画像ダウンロード時に拡張子が保存されない

🔴 高 | ✅ 修正完了

---

## 問題

画像をダウンロードすると拡張子なしで保存され、ファイルが開けない。

### ログ
```
📝 拡張子:
📄 QuickLookで表示:
Unhandled item type 15: contentType is: public.data
```

---

## 原因

ダウンロード時にファイル名から拡張子が取得できていない、またはURLに拡張子がない。

---

## 修正方針

1. Content-Typeから拡張子を推測
2. URLから拡張子を取得
3. デフォルトで適切な拡張子を付与

---

## 関連ファイル

- [DownloadManager.swift](../../VanishBrowser/VanishBrowser/Services/DownloadManager.swift)
- [FileViewerView.swift](../../VanishBrowser/VanishBrowser/Views/FileViewerView.swift)
