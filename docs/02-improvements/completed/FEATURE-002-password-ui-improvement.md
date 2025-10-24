# FEATURE-002: パスワード入力画面のUI改善

🟡 P2 Medium | ⏳ 動作確認待ち

---

## 問題

パスワード入力画面のテキストフィールドが画面中央にあり、iPhoneのようにキーボード付近に配置されていない。
タッチで簡単に入力できるようにしたい。

---

## 実装内容

画面を上下に分割し、入力欄を下部に配置するレイアウトに変更しました。

### 変更点

1. **AuthenticationView.swift**: レイアウトを上下分割に変更
   - `GeometryReader` で画面サイズを取得
   - 上部50%: アイコンとタイトル
   - 下部: パスワード入力欄とボタン（キーボード付近）
   - `.ignoresSafeArea(.keyboard)` でキーボード表示時の調整

### 効果

- 入力フィールドがキーボードのすぐ上に表示
- iPhoneの標準的な入力画面に近いUX
- タッチで入力しやすい配置

---

## 関連ファイル

- [AuthenticationView.swift](../../VanishBrowser/VanishBrowser/Views/AuthenticationView.swift)
