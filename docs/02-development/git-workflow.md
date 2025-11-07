# Git運用フロー

**最終更新: 2025-10-29**

---

## ブランチ戦略

VanishBrowserは **Git Flow ライク** な運用を行います。

```
main (本番リリース版、保護)
  ↑ PR
develop (開発ブランチ、デフォルト)
  ↑ 直接コミット or PR
feature/xxx, fix/xxx (作業ブランチ)
```

### ブランチの役割

| ブランチ | 役割 | 保護 | 誰がコミット |
|---------|------|------|------------|
| `main` | App Store提出版、リリースタグ管理 | ✅ | PRのみ |
| `develop` | 日常開発、動作確認済みコード | ❌ | 直接コミット可 |
| `feature/xxx` | 新機能開発 | ❌ | 作業者 |
| `fix/xxx` | バグ修正 | ❌ | 作業者 |

---

## 日常開発フロー

### 1. 基本的な作業（developで直接コミット）

```bash
# developブランチで作業
git checkout develop
git pull

# ファイル修正
# ...

# コミット（動作確認OK後のみ）
git add .
git commit -m "fix: BUG-040 ..."
git push origin develop
```

### 2. 大きな機能追加（featureブランチ）

```bash
# featureブランチ作成
git checkout develop
git pull
git checkout -b feature/FEATURE-010-dark-mode

# 実装 → コミット
git add .
git commit -m "feat: FEATURE-010 ダークモード実装"
git push origin feature/FEATURE-010-dark-mode

# developにマージ（動作確認OK後）
git checkout develop
git merge feature/FEATURE-010-dark-mode
git push origin develop

# featureブランチ削除
git branch -d feature/FEATURE-010-dark-mode
git push origin --delete feature/FEATURE-010-dark-mode
```

### 3. バグ修正（fixブランチ）

```bash
# fixブランチ作成
git checkout develop
git checkout -b fix/BUG-040-crash-on-launch

# 修正 → コミット
git add .
git commit -m "fix: BUG-040 起動時クラッシュ修正"
git push origin fix/BUG-040-crash-on-launch

# developにマージ（動作確認OK後）
git checkout develop
git merge fix/BUG-040-crash-on-launch
git push origin develop

# fixブランチ削除
git branch -d fix/BUG-040-crash-on-launch
git push origin --delete fix/BUG-040-crash-on-launch
```

---

## リリースフロー

### 1. develop → main へPR作成

**IMPORTANT**: PR本文の最初にリリースノート形式で変更内容を記載すること

#### リリースノート形式（PR本文テンプレート）

```markdown
バージョンX.X.Xの新機能

【新機能】
• 機能A
• 機能B

【改善点】
• 改善C
• 改善D

【バグ修正】
• 修正E
• 修正F

---

## 詳細な変更内容
- BUG-XXX: ...
- FEATURE-XXX: ...

## 動作確認
- ✅ 全機能テスト完了
- ✅ iPhone 15/16実機確認済み
```

#### 実際の例（v1.0.3の場合）

```markdown
バージョン1.0.3の新機能

【新機能】
• タブのドラッグ並び替え機能
• 新規タブ作成時の自動フォーカス

【改善点】
• iPhone 16で動画プレーヤーの表示を最適化
• ブックマーク機能を改善
• 設定画面のデザインを刷新
• 動画プレーヤーのアニメーションを改善
• プライベートモード使用時の安定性向上

【バグ修正】
• 各種UIの表示問題を修正
• タブ操作の不具合を修正

---

## 詳細な変更内容
- BUG-036: iPhone 16でカスタム動画プレーヤーのコントロールが見切れる問題を修正
- BUG-037: 動画ナビゲーションコントロール追加
- FEATURE-009: タブドラッグ並び替え機能実装
...

## 動作確認
- ✅ 全機能テスト完了
- ✅ iPhone 15/16実機確認済み
```

#### コマンド例

```bash
# developが安定していることを確認
git checkout develop
git pull

# GitHub UIでPR作成
# Base: main
# Compare: develop
# Title: "Release v1.1 - 新機能追加"
# Body: 上記のリリースノート形式で記載
```

または

```bash
# GitHub CLIでPR作成
gh pr create --base main --head develop \
  --title "Release v1.1 - 新機能追加" \
  --body "バージョン1.1の新機能

【新機能】
• ダークモード追加

【改善点】
• パフォーマンス向上

【バグ修正】
• 動画スワイプナビゲーション修正

---

## 詳細な変更内容
- BUG-037: 動画スワイプナビゲーション
- BUG-038: 動画ツールバー修正
- FEATURE-011: ダークモード追加

## 動作確認
- ✅ 全機能テスト完了
- ✅ iPhone 15/16実機確認済み
"
```

### 2. PRレビュー & マージ

```bash
# GitHub UIでPRをマージ
# または
gh pr merge --squash
```

### 3. タグ作成 & App Store提出

```bash
# mainブランチでタグ作成
git checkout main
git pull

# バージョンタグ作成
git tag -a v1.1 -m "App Store提出版 v1.1"
git push origin v1.1

# App Store Connect でArchive提出
# Xcode > Product > Archive
```

### 4. developに戻る

```bash
# 次の開発を続ける
git checkout develop
git pull origin develop
```

---

## コミットメッセージ規約

### フォーマット

```
<type>: <subject>

<body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Type

| Type | 説明 | 例 |
|------|------|-----|
| `fix` | バグ修正 | `fix: BUG-040 起動時クラッシュ修正` |
| `feat` | 新機能 | `feat: FEATURE-011 ダークモード追加` |
| `docs` | ドキュメント | `docs: Git運用フロー追加` |
| `refactor` | リファクタリング | `refactor: DownloadService整理` |
| `test` | テスト追加 | `test: DownloadManagerのテスト追加` |
| `chore` | ビルド設定など | `chore: Xcode 15.2対応` |

### Subject（1行目）

- ✅ 命令形で書く: "修正する" ではなく "修正"
- ✅ チケット番号を含める: `BUG-040`, `FEATURE-011`
- ✅ 50文字以内
- ❌ 句点（。）は不要

### 良い例

```bash
fix: BUG-040 ファイル移動後のUI更新問題を修正
feat: FEATURE-011 ダークモード実装
docs: Git運用フローをドキュメント化
```

### 悪い例

```bash
修正  # typeがない
fix: 修正しました。  # チケット番号がない、句点がある
fixed bug  # 日本語プロジェクトなので日本語で
```

---

## ブランチ保護設定（GitHub）

### main ブランチ保護

https://github.com/gminoshiro/vanish-browser/settings/branches

1. **Add rule**
2. Branch name pattern: `main`
3. 設定:
   - ✅ **Require a pull request before merging**
   - ✅ **Require approvals**: 1
   - ✅ **Dismiss stale pull request approvals when new commits are pushed**
   - ❌ Require status checks (CI未導入のため)
4. **Create**

---

## トラブルシューティング

### 間違えてmainに直接コミットした

```bash
# コミットを取り消し（ローカル）
git reset --soft HEAD~1

# developに切り替えてコミット
git checkout develop
git add .
git commit -m "fix: ..."
git push origin develop
```

### developとmainが diverged（分岐）した

```bash
# mainの変更をdevelopに取り込む
git checkout develop
git pull origin main
git push origin develop
```

### 古いfeatureブランチを削除したい

```bash
# ローカルブランチ削除
git branch -d feature/old-feature

# リモートブランチ削除
git push origin --delete feature/old-feature

# または一括削除（developにマージ済みブランチ）
git branch --merged develop | grep -v "^\*\|main\|develop" | xargs git branch -d
```

---

## 参考リンク

- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)

---

**次のステップ:** [DEV.md](../../DEV.md) で開発ルール全体を確認
