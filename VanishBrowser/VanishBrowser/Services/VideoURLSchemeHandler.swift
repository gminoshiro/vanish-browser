//
//  VideoURLSchemeHandler.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/12.
//

import Foundation
import WebKit

class VideoURLSchemeHandler: NSObject, WKURLSchemeHandler {

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        // vanish-video:// スキームのリクエストを処理
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(NSError(domain: "VideoHandler", code: -1, userInfo: nil))
            return
        }

        // 元のHTTP URLを復元
        let originalURLString = url.absoluteString.replacingOccurrences(of: "vanish-video://", with: "https://")

        print("🎬 動画リクエストをインターセプト: \(originalURLString)")

        // 動画検出通知を送信
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("VideoRequestIntercepted"),
                object: nil,
                userInfo: ["url": originalURLString, "fileName": URL(string: originalURLString)?.lastPathComponent ?? "video.mp4"]
            )
        }

        // リクエストを中断（動画を読み込まない）
        urlSchemeTask.didFailWithError(NSError(domain: "VideoHandler", code: NSURLErrorCancelled, userInfo: nil))
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // 必要に応じてクリーンアップ
    }
}
