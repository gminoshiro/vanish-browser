#!/usr/bin/env python3
"""
Vanish Browser アイコン生成スクリプト
プライバシーを象徴する消えていくイメージのアイコンを生成
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon():
    # 1024x1024のアイコンを作成（App Store用）
    size = 1024
    image = Image.new('RGB', (size, size), color='#1a1a2e')  # ダークブルー背景
    draw = ImageDraw.Draw(image)

    # グラデーション効果（手動で複数の円を描画）
    center_x, center_y = size // 2, size // 2

    # 消えていく円（フェードアウト効果）
    circles = [
        (300, '#4a5fff', 255),  # 内側：明るい青、不透明
        (400, '#3a4fee', 200),  # 中間
        (500, '#2a3edd', 150),  # 中間
        (600, '#1a2ecc', 100),  # 外側：暗い青、半透明
    ]

    for radius, color, alpha in circles:
        # 透明度を考慮した円を描画
        temp_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        temp_draw = ImageDraw.Draw(temp_img)

        # RGB値を取得
        r = int(color[1:3], 16)
        g = int(color[3:5], 16)
        b = int(color[5:7], 16)

        temp_draw.ellipse(
            [center_x - radius, center_y - radius, center_x + radius, center_y + radius],
            fill=(r, g, b, alpha)
        )

        # アルファブレンド
        image = Image.alpha_composite(image.convert('RGBA'), temp_img).convert('RGB')

    # 中央に鍵のシンボル（プライバシーを象徴）
    # シンプルな鍵の形
    draw = ImageDraw.Draw(image)

    # 鍵の円形部分
    lock_x, lock_y = center_x, center_y - 80
    lock_radius = 60
    draw.ellipse(
        [lock_x - lock_radius, lock_y - lock_radius, lock_x + lock_radius, lock_y + lock_radius],
        outline='white', width=20
    )

    # 鍵の内側の円
    inner_radius = 30
    draw.ellipse(
        [lock_x - inner_radius, lock_y - inner_radius, lock_x + inner_radius, lock_y + inner_radius],
        fill='#1a1a2e'
    )

    # 鍵の柄部分
    handle_width = 40
    handle_height = 120
    handle_top = lock_y + lock_radius - 10
    draw.rectangle(
        [lock_x - handle_width//2, handle_top, lock_x + handle_width//2, handle_top + handle_height],
        fill='white'
    )

    # 鍵の切り込み
    notch_width = 60
    notch_height = 20
    notch_y = handle_top + handle_height - 40
    draw.rectangle(
        [lock_x + handle_width//2, notch_y, lock_x + handle_width//2 + notch_width, notch_y + notch_height],
        fill='white'
    )

    # 下の切り込み
    notch_y2 = handle_top + handle_height - 10
    draw.rectangle(
        [lock_x + handle_width//2, notch_y2, lock_x + handle_width//2 + notch_width, notch_y2 + notch_height],
        fill='white'
    )

    # アイコンを保存
    output_path = '/Users/genfutoshi/vanish-browser/VanishBrowser/VanishBrowser/Assets.xcassets/AppIcon.appiconset/icon_1024.png'
    image.save(output_path)
    print(f"✅ アイコンを作成しました: {output_path}")

    # Contents.jsonを更新
    update_contents_json()

def update_contents_json():
    contents_json = """{
  "images" : [
    {
      "filename" : "icon_1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

    json_path = '/Users/genfutoshi/vanish-browser/VanishBrowser/VanishBrowser/Assets.xcassets/AppIcon.appiconset/Contents.json'
    with open(json_path, 'w') as f:
        f.write(contents_json)
    print(f"✅ Contents.jsonを更新しました: {json_path}")

if __name__ == '__main__':
    create_app_icon()
    print("\n🎨 Vanish Browser アイコンの生成が完了しました！")
    print("📱 Xcodeでプロジェクトを開いてアイコンを確認してください。")
