//
//  VideoInterceptor.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/12.
//

import Foundation
import AVKit
import WebKit

class VideoInterceptor {
    static let shared = VideoInterceptor()

    private var observation: NSObjectProtocol?
    private var videoWindow: UIWindow?
    private var monitorTimer: Timer?
    private var processedWindows = Set<UIWindow>()

    private init() {
        setupVideoInterception()
        startContinuousMonitoring()
    }

    private func setupVideoInterception() {
        // AVPlayerViewControllerの表示を監視（複数の通知を監視）

        // 1. ウィンドウがキーになる前に検知
        observation = NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeVisibleNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? UIWindow else { return }

            // ビデオプレーヤーのウィンドウを検出
            if self?.isVideoPlayerWindow(window) == true {
                print("🎬 ビデオプレーヤーウィンドウを検出（Visible）！")
                self?.interceptVideoPlayer(window: window)
            }
        }

        // 2. ウィンドウがキーになった時にも検知
        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? UIWindow else { return }

            // ビデオプレーヤーのウィンドウを検出
            if self?.isVideoPlayerWindow(window) == true {
                print("🎬 ビデオプレーヤーウィンドウを検出（Key）！")
                self?.interceptVideoPlayer(window: window)
            }
        }
    }

    // 継続的にウィンドウを監視（0.1秒ごと）
    private func startContinuousMonitoring() {
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkForVideoPlayerWindows()
        }
    }

    // 全てのウィンドウをチェック
    private func checkForVideoPlayerWindows() {
        guard let scenes = UIApplication.shared.connectedScenes as? Set<UIWindowScene> else { return }

        for scene in scenes {
            for window in scene.windows {
                // 全ウィンドウのクラス名をチェック（デバッグ用）
                let windowClass = NSStringFromClass(type(of: window))
                let rootVCClass = window.rootViewController.map { NSStringFromClass(type(of: $0)) } ?? "nil"

                // AVPlayer関連のウィンドウを検出
                if (windowClass.contains("AVPlayerViewController") ||
                    windowClass.contains("PIPWindow") ||
                    windowClass.contains("AVKit") ||
                    rootVCClass.contains("AVPlayerViewController") ||
                    window.rootViewController is AVPlayerViewController) &&
                   !processedWindows.contains(window) {
                    print("🎬 ポーリングでビデオプレーヤーウィンドウを検出！")
                    print("🎬 ウィンドウクラス: \(windowClass)")
                    print("🎬 rootViewController: \(rootVCClass)")
                    interceptVideoPlayer(window: window)
                }
            }
        }
    }

    private func isVideoPlayerWindow(_ window: UIWindow) -> Bool {
        // AVPlayerViewControllerのウィンドウかどうか判定
        let windowClass = NSStringFromClass(type(of: window))
        let rootVCClass = window.rootViewController.map { NSStringFromClass(type(of: $0)) } ?? ""

        return windowClass.contains("AVPlayerViewController") ||
               windowClass.contains("PIPWindow") ||
               windowClass.contains("AVKit") ||
               rootVCClass.contains("AVPlayerViewController") ||
               window.rootViewController is AVPlayerViewController
    }

    private func interceptVideoPlayer(window: UIWindow) {
        // 処理済みとしてマーク
        processedWindows.insert(window)

        print("🎬 ビデオプレーヤーをインターセプト開始")

        // まず即座にウィンドウを非表示にする（ユーザーに見せない）
        window.isHidden = true
        window.alpha = 0
        print("✅ ウィンドウを即座に非表示化")

        // 動画URLを取得
        var videoURL: URL?
        if let playerVC = window.rootViewController as? AVPlayerViewController,
           let player = playerVC.player,
           let currentItem = player.currentItem,
           let asset = currentItem.asset as? AVURLAsset {

            videoURL = asset.url
            print("🎬 インターセプトした動画URL: \(asset.url.absoluteString)")

            // プレーヤーを即座に停止
            player.pause()
            player.rate = 0
            player.replaceCurrentItem(with: nil)
        }

        // カスタムプレーヤー表示の通知を送信（URLがあれば）
        if let url = videoURL {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowCustomVideoPlayer"),
                    object: nil,
                    userInfo: [
                        "url": url,
                        "fileName": url.lastPathComponent,
                        "isDownloaded": false
                    ]
                )
            }
        }

        // ビデオプレーヤーウィンドウを即座に完全破棄
        if let playerVC = window.rootViewController as? AVPlayerViewController {
            playerVC.dismiss(animated: false, completion: nil)
            playerVC.player = nil
        }

        // ウィンドウを完全に無効化
        window.rootViewController = nil
        window.windowScene = nil
        window.isHidden = true

        // メインウィンドウをアクティブに
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let mainWindow = scene.windows.first(where: { !self.isVideoPlayerWindow($0) }) {
                mainWindow.makeKeyAndVisible()
                print("✅ メインウィンドウを再表示")
            }
        }

        // 念のため0.5秒後にも再度破棄処理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            window.isHidden = true
            window.alpha = 0
            window.rootViewController = nil
            window.windowScene = nil
        }

        print("✅ ビデオプレーヤーウィンドウを破棄")
    }

    deinit {
        monitorTimer?.invalidate()
        if let observation = observation {
            NotificationCenter.default.removeObserver(observation)
        }
    }
}
