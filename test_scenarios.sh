#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 VanishBrowser シナリオテスト実行スクリプト"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# テスト結果ディレクトリ
TEST_RESULT_DIR="/tmp/vanish_browser_test_results"
mkdir -p "$TEST_RESULT_DIR"

# アプリのバンドルID
BUNDLE_ID="com.genfutoshi.VanishBrowser"

# シミュレーターID
SIMULATOR_ID="17873ACC-27D6-45B7-8CDB-1E70E0795968"

# シミュレーター起動確認
echo "📱 シミュレーター起動確認..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "  (すでに起動済み)"

# アプリがインストールされているか確認
echo "📦 アプリインストール確認..."
if xcrun simctl listapps "$SIMULATOR_ID" | grep -q "$BUNDLE_ID"; then
    echo "  ✅ アプリがインストールされています"
else
    echo "  ❌ アプリがインストールされていません"
    echo "  → Xcodeから一度アプリをビルド・インストールしてください"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 シナリオテスト実施計画"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "以下のシナリオは手動実施が必要です："
echo ""
echo "✅ シナリオ1: 画像10個ダウンロード"
echo "   手順:"
echo "   1. アプリを起動"
echo "   2. 画像サイトにアクセス（例: unsplash.com）"
echo "   3. 画像を長押しして10個ダウンロード"
echo "   4. ダウンロードリストで10個確認"
echo ""
echo "✅ シナリオ2: 動画10個ダウンロード"
echo "   手順:"
echo "   1. 動画サイトにアクセス"
echo "   2. 動画検出されたら「動画をダウンロード」をタップ"
echo "   3. 10個の動画をダウンロード"
echo "   4. ダウンロードリストで10個確認"
echo ""
echo "✅ シナリオ3: 画像10個 + 動画10個 + 内容確認"
echo "   手順:"
echo "   1. 画像10個ダウンロード"
echo "   2. 動画10個ダウンロード"
echo "   3. ダウンロードリストで合計20個確認"
echo "   4. 各ファイルをタップして内容確認"
echo "   5. ストレージ使用量を設定画面で確認"
echo ""
echo "✅ シナリオ4: ダウンロード + 自動削除"
echo "   手順:"
echo "   1. 画像5個 + 動画5個ダウンロード"
echo "   2. 設定 → 自動削除設定を開く"
echo "   3. 「今すぐすべて削除」をタップ"
echo "   4. 確認ダイアログで「削除」を選択"
echo "   5. ダウンロードリストが空になることを確認"
echo ""
echo "✅ シナリオ5: 重複ファイル名"
echo "   手順:"
echo "   1. 同じ画像を3回ダウンロード"
echo "   2. ダウンロードリストで3個のファイル確認"
echo "   3. ファイル名が「image.jpg」「image (1).jpg」「image (2).jpg」になっていることを確認"
echo ""
echo "✅ シナリオ6: フォルダ分け"
echo "   手順:"
echo "   1. ダウンロード時にフォルダ「仕事」を選択して画像保存"
echo "   2. 別の画像を「プライベート」フォルダに保存"
echo "   3. ダウンロードリストでフォルダ別に表示されることを確認"
echo ""
echo "✅ シナリオ7: 大量ダウンロード（50個）+ ストレージ計算"
echo "   手順:"
echo "   1. 画像を50個ダウンロード"
echo "   2. 設定 → ストレージで総使用量を確認"
echo "   3. ダウンロードリストでスクロールが正常に動作することを確認"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 自動確認可能な項目"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Core Dataのストレージパスを取得
APP_DATA_DIR=$(find ~/Library/Developer/CoreSimulator/Devices/$SIMULATOR_ID/data/Containers/Data/Application -name "com.genfutoshi.VanishBrowser" -type d 2>/dev/null | head -1)

if [ -z "$APP_DATA_DIR" ]; then
    echo "⚠️  アプリのデータディレクトリが見つかりません"
    echo "   アプリを一度起動してデータを作成してください"
    exit 1
fi

echo "📂 アプリデータディレクトリ:"
echo "   $APP_DATA_DIR"
echo ""

# ダウンロードフォルダ確認
DOWNLOAD_DIR="$APP_DATA_DIR/Documents/Downloads"
if [ -d "$DOWNLOAD_DIR" ]; then
    FILE_COUNT=$(find "$DOWNLOAD_DIR" -type f | wc -l | xargs)
    TOTAL_SIZE=$(du -sh "$DOWNLOAD_DIR" 2>/dev/null | awk '{print $1}')

    echo "✅ ダウンロードフォルダ確認:"
    echo "   ファイル数: $FILE_COUNT 個"
    echo "   総サイズ: $TOTAL_SIZE"
    echo ""

    if [ $FILE_COUNT -gt 0 ]; then
        echo "📋 ダウンロード済みファイル一覧:"
        find "$DOWNLOAD_DIR" -type f -exec basename {} \; | head -20
        if [ $FILE_COUNT -gt 20 ]; then
            echo "   ... 他 $((FILE_COUNT - 20)) 個"
        fi
    fi
else
    echo "⚠️  ダウンロードフォルダが見つかりません"
    echo "   まだファイルがダウンロードされていません"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 テスト実施ガイド"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. シミュレーターを開く:"
echo "   open -a Simulator"
echo ""
echo "2. アプリを起動:"
echo "   xcrun simctl launch $SIMULATOR_ID $BUNDLE_ID"
echo ""
echo "3. 上記のシナリオを順番に実施"
echo ""
echo "4. 各シナリオ実施後、このスクリプトを再実行して状態確認:"
echo "   bash test_scenarios.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 よく使うテストサイト"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "画像ダウンロード:"
echo "  • https://unsplash.com/ (高品質画像)"
echo "  • https://www.pexels.com/ (フリー画像)"
echo ""
echo "動画ダウンロード:"
echo "  • https://sample-videos.com/ (サンプル動画)"
echo "  • https://www.youtube.com/ (動画検出テスト)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
