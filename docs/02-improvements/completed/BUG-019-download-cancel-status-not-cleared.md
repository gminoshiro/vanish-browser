# BUG-019: ダウンロードキャンセル後「ダウンロード中」が消えない

🔴 P0 Critical | ✅ 修正完了

---

## 問題

ダウンロード中にキャンセルしても「ダウンロード中」ステータスが消えない。

---

## 原因

HLSダウンロードが各ダウンロードごとに新しい`HLSDownloader()`インスタンスを作成していたため、UI状態が保持されず、キャンセルボタンも表示されていなかった。

---

## 実装内容

### 変更点

#### 1. BrowserView.swift

`HLSDownloader`を`@StateObject`として保持し、ダウンロード状態を監視できるようにした：

```swift
@StateObject private var hlsDownloader = HLSDownloader()
```

HLSダウンロード中のオーバーレイUIを追加：

```swift
.overlay(
    Group {
        if hlsDownloader.isDownloading {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("HLSダウンロード中")
                        .font(.headline)
                        .foregroundColor(.white)

                    ProgressView(value: hlsDownloader.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(width: 200)

                    Text("\(Int(hlsDownloader.progress * 100))%")

                    if hlsDownloader.totalSegments > 0 {
                        Text("\(hlsDownloader.downloadedSegments) / \(hlsDownloader.totalSegments) セグメント")
                    }

                    Button(action: {
                        hlsDownloader.cancel()
                    }) {
                        Text("キャンセル")
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
)
```

#### 2. HLSDownloader.swift

キャンセル処理を改善し、一時ファイルの削除と状態リセットを追加：

```swift
private var currentTempFolder: URL?

func cancel() {
    print("🛑 ダウンロードキャンセル要求")
    downloadTask?.cancel()
    isDownloading = false

    // 一時フォルダを削除
    if let tempFolder = currentTempFolder {
        try? FileManager.default.removeItem(at: tempFolder)
        print("🗑️ 一時フォルダ削除: \(tempFolder.lastPathComponent)")
        currentTempFolder = nil
    }

    // 状態をリセット
    progress = 0.0
    downloadedSegments = 0
    totalSegments = 0
    downloadedSize = 0
}
```

---

## 効果

1. ✅ **HLSダウンロード中の視覚的フィードバック**
   - プログレスバーとパーセンテージ表示
   - セグメント数の表示

2. ✅ **キャンセルボタンの表示**
   - ダウンロード中にキャンセル可能

3. ✅ **キャンセル時のクリーンアップ**
   - 一時フォルダとファイルを削除
   - UI状態を即座にリセット
   - 「ダウンロード中」表示が正しく消える

---

## テスト方法

1. HLS動画をダウンロード開始
2. ダウンロード中のオーバーレイが表示されることを確認
3. プログレスバーが更新されることを確認
4. 「キャンセル」ボタンを押す
5. オーバーレイが即座に消えることを確認
6. 一時ファイルが削除されることを確認

---

## 関連ファイル

- [BrowserView.swift](../../VanishBrowser/VanishBrowser/Views/BrowserView.swift)
- [HLSDownloader.swift](../../VanishBrowser/VanishBrowser/Services/HLSDownloader.swift)

---

## 作成日

2025-10-17

## 完了日

2025-10-17
