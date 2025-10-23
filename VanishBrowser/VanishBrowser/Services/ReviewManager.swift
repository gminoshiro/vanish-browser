//
//  ReviewManager.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/22.
//

import StoreKit
import UIKit

class ReviewManager {
    static let shared = ReviewManager()

    private let launchCountKey = "appLaunchCount"
    private let hasRequestedReviewKey = "hasRequestedReview_v1.0"

    private init() {}

    /// アプリ起動時に呼ぶ
    func incrementLaunchCount() {
        let count = UserDefaults.standard.integer(forKey: launchCountKey)
        UserDefaults.standard.set(count + 1, forKey: launchCountKey)
        print("📊 アプリ起動回数: \(count + 1)")
    }

    /// レビュー依頼が適切か判定して実行
    func requestReviewIfAppropriate() {
        let launchCount = UserDefaults.standard.integer(forKey: launchCountKey)
        let hasRequested = UserDefaults.standard.bool(forKey: hasRequestedReviewKey)

        print("📊 レビュー依頼チェック: 起動回数=\(launchCount), 既依頼=\(hasRequested)")

        // 10回目の起動 かつ まだ依頼していない
        if launchCount == 10 && !hasRequested {
            print("⭐ レビュー依頼を表示します")
            requestReview()
            UserDefaults.standard.set(true, forKey: hasRequestedReviewKey)
        }
    }

    /// レビュー依頼を表示
    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("❌ UIWindowSceneが取得できません")
            return
        }

        // 2秒遅延（自然な体験）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            SKStoreReviewController.requestReview(in: scene)
            print("✅ レビュー依頼ダイアログを表示しました")
        }
    }

    /// 設定画面から手動でレビュー画面を開く
    func openReviewPage(appID: String) {
        let urlString = "https://apps.apple.com/app/id\(appID)?action=write-review"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
            print("🔗 レビューページを開きます: \(urlString)")
        }
    }

    /// デバッグ用: 起動回数をリセット
    func resetLaunchCount() {
        UserDefaults.standard.set(0, forKey: launchCountKey)
        UserDefaults.standard.set(false, forKey: hasRequestedReviewKey)
        print("🔄 起動回数とレビュー依頼フラグをリセットしました")
    }
}
