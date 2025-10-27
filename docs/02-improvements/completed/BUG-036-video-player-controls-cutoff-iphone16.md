# BUG-036: カスタム動画プレーヤーのコントロールがiPhone 16で見切れる

**ステータス**: ✅ 完了
**優先度**: Critical
**作成日**: 2025-10-27
**完了日**: 2025-10-27

---

## 問題

iPhone 16実機およびシミュレータ(iOS 26.0)で、カスタム動画プレーヤーの全てのコントロールが見切れて表示される問題。

### 症状
- 閉じるボタン(右上)が完全に見えない
- ダウンロードボタン(左下)が見切れる
- 再生バーの右側の時間表示が見切れる
- 再生/一時停止など全てのコントロールが見切れる

### 原因
`.safeAreaPadding()` APIがiOS 26で正しく動作していない。Dynamic IslandやSafe Areaの処理に不具合がある。

---

## 解決策

### 実装内容

**ファイル**: `VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift`

1. **GeometryReaderでSafe Area値を明示的に取得**
   - `.safeAreaPadding()`を削除
   - `GeometryReader`と`geometry.safeAreaInsets`を使用

2. **上部パディング修正**
   ```swift
   .padding(.top, max(geometry.safeAreaInsets.top, 16))
   ```

3. **下部パディング修正**
   ```swift
   .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
   ```

4. **明示的なフレーム指定**
   ```swift
   .frame(width: geometry.size.width, height: geometry.size.height)
   ```

5. **ボタンサイズ縮小（見切れ対策）**
   - DLボタン: 40pt → 32pt (背景円: 44pt → 36pt)
   - 巻き戻し/早送り: 36pt → 32pt
   - 再生ボタン: 40pt → 36pt
   - メニューボタン: 28pt → 24pt (枠: 44pt → 36pt)
   - ボタン間隔: 30pt → 24pt
   - 左右パディング: 20pt → 24pt

---

## 動作確認

✅ iPhone 16e シミュレータ(iOS 26.0)
- 全てのボタンが表示される
- タップ操作が正常に動作
- Safe Areaが正しく考慮される

---

## 技術詳細

### iOS 26での変更点
- `.safeAreaPadding()`の挙動が変更された
- Dynamic Island搭載機種でのSafe Area処理が不安定

### 採用した解決方法
- `GeometryReader`で正確なSafe Area値を取得
- `max()`で最小パディングを保証
- 明示的なフレームサイズ指定で確実な配置

---

## 関連ファイル

- `VanishBrowser/VanishBrowser/Views/CustomVideoPlayerView.swift`

---

**修正完了 - 動作確認OK**
