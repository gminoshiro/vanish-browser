//
//  BrowserViewModel.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import Foundation
import WebKit
import Combine
import UIKit

class BrowserViewModel: NSObject, ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var currentURL: String = ""
    @Published var isLoading = false
    @Published var downloadProgress: Float = 0.0
    @Published var isDownloading = false
    @Published var detectedMediaURL: URL?
    @Published var detectedMediaFileName: String?

    let webView: WKWebView
    private var cancellables = Set<AnyCancellable>()

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent() // プライバシー保護：永続化しない

        // すべてのメディア操作を無効化（長押しメニュー完全ブロック）
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // JavaScriptでメディア要素を検出するスクリプト
        let mediaDetectionScript = WKUserScript(
            source: """
            function detectMedia() {
                const videos = document.querySelectorAll('video');
                const audios = document.querySelectorAll('audio');

                if (videos.length > 0) {
                    const video = videos[0];
                    let videoUrl = video.src || video.currentSrc;

                    // srcがない場合はsource要素を確認
                    if (!videoUrl) {
                        const sources = video.querySelectorAll('source');
                        if (sources.length > 0) {
                            videoUrl = sources[0].src;
                        }
                    }

                    if (videoUrl && videoUrl.startsWith('http')) {
                        window.webkit.messageHandlers.mediaDetected.postMessage({
                            type: 'video',
                            url: videoUrl,
                            fileName: videoUrl.split('/').pop().split('?')[0] || 'video.mp4'
                        });
                    }
                } else if (audios.length > 0) {
                    const audio = audios[0];
                    let audioUrl = audio.src || audio.currentSrc;

                    if (!audioUrl) {
                        const sources = audio.querySelectorAll('source');
                        if (sources.length > 0) {
                            audioUrl = sources[0].src;
                        }
                    }

                    if (audioUrl && audioUrl.startsWith('http')) {
                        window.webkit.messageHandlers.mediaDetected.postMessage({
                            type: 'audio',
                            url: audioUrl,
                            fileName: audioUrl.split('/').pop().split('?')[0] || 'audio.mp3'
                        });
                    }
                }
            }

            // 複数回チェック
            setTimeout(detectMedia, 500);
            setTimeout(detectMedia, 1500);
            setTimeout(detectMedia, 3000);
            document.addEventListener('DOMContentLoaded', detectMedia);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )

        // コンテキストメニュー完全ブロックと画像長押し検出スクリプト
        let imageTapScript = WKUserScript(
            source: """
            (function() {
                // CSSでユーザー選択とコンテキストメニューを無効化
                var style = document.createElement('style');
                style.innerHTML = `
                    * {
                        -webkit-touch-callout: none !important;
                        -webkit-user-select: none !important;
                    }
                    img, video {
                        pointer-events: auto !important;
                    }
                `;
                document.head.appendChild(style);

                // 複数の方法でコンテキストメニューをブロック
                function blockContextMenu(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    e.stopImmediatePropagation();
                    return false;
                }

                document.addEventListener('contextmenu', blockContextMenu, true);
                document.addEventListener('contextmenu', blockContextMenu, false);

                // selectstartイベントもブロック
                document.addEventListener('selectstart', function(e) {
                    if (e.target.tagName === 'IMG' || e.target.tagName === 'VIDEO') {
                        e.preventDefault();
                        return false;
                    }
                }, true);

                // 長押し検出
                var longPressTimer = null;
                var touchTarget = null;
                var touchMoved = false;

                document.addEventListener('touchstart', function(e) {
                    touchTarget = e.target;
                    touchMoved = false;

                    // 画像の場合は長押しタイマー開始
                    if (e.target && e.target.tagName === 'IMG') {
                        // デフォルト動作を即座にブロック
                        e.preventDefault();

                        longPressTimer = setTimeout(function() {
                            if (!touchMoved) {
                                var img = e.target;
                                var imageUrl = img.src || img.currentSrc;

                                if (imageUrl && imageUrl.startsWith('http')) {
                                    window.webkit.messageHandlers.imageLongPress.postMessage({
                                        url: imageUrl,
                                        fileName: imageUrl.split('/').pop().split('?')[0] || 'image.jpg'
                                    });
                                }
                            }
                        }, 500);
                    }
                }, { capture: true, passive: false });

                document.addEventListener('touchmove', function(e) {
                    touchMoved = true;
                    // スクロールしたらタイマーキャンセル
                    if (longPressTimer) {
                        clearTimeout(longPressTimer);
                        longPressTimer = null;
                    }
                }, true);

                document.addEventListener('touchend', function(e) {
                    // タッチ終了でタイマーキャンセル
                    if (longPressTimer) {
                        clearTimeout(longPressTimer);
                        longPressTimer = null;
                    }
                }, true);

                document.addEventListener('touchcancel', function(e) {
                    // タッチキャンセルでタイマーキャンセル
                    if (longPressTimer) {
                        clearTimeout(longPressTimer);
                        longPressTimer = null;
                    }
                }, true);

                // 画像に直接イベントリスナーを追加（動的に追加される画像にも対応）
                var observer = new MutationObserver(function(mutations) {
                    document.querySelectorAll('img').forEach(function(img) {
                        img.addEventListener('contextmenu', blockContextMenu, true);
                    });
                });

                observer.observe(document.body || document.documentElement, {
                    childList: true,
                    subtree: true
                });
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )

        configuration.userContentController.addUserScript(mediaDetectionScript)
        configuration.userContentController.addUserScript(imageTapScript)

        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()

        // Message handlerを追加（WebView作成後に追加）
        webView.configuration.userContentController.add(self, name: "mediaDetected")
        webView.configuration.userContentController.add(self, name: "imageLongPress")
        webView.navigationDelegate = self

        // WebViewの状態を監視
        webView.publisher(for: \.canGoBack)
            .assign(to: &$canGoBack)

        webView.publisher(for: \.canGoForward)
            .assign(to: &$canGoForward)

        webView.publisher(for: \.isLoading)
            .assign(to: &$isLoading)

        // 初期ページをロード（DuckDuckGo）
        loadURL("https://duckduckgo.com")
    }

    deinit {
        // Message handlerを削除してメモリリークを防ぐ
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "mediaDetected")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "imageLongPress")
    }

    func loadURL(_ urlString: String) {
        var urlToLoad = urlString.trimmingCharacters(in: .whitespaces)

        // URLスキームがない場合は検索と判断
        if !urlToLoad.hasPrefix("http://") && !urlToLoad.hasPrefix("https://") {
            // スペースがあるか、ドメインっぽくない場合は検索
            if urlToLoad.contains(" ") || !urlToLoad.contains(".") {
                // DuckDuckGoで検索
                urlToLoad = "https://duckduckgo.com/?q=\(urlToLoad.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            } else {
                urlToLoad = "https://" + urlToLoad
            }
        }

        guard let url = URL(string: urlToLoad) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }

    func reload() {
        webView.reload()
    }

    func downloadFile(from url: URL, fileName: String) {
        isDownloading = true
        downloadProgress = 0.0

        DownloadService.shared.downloadFile(from: url, fileName: fileName) { [weak self] success in
            DispatchQueue.main.async {
                self?.isDownloading = false
                self?.downloadProgress = 0.0
                if success {
                    print("ダウンロード成功: \(fileName)")
                }
            }
        }
    }
}

// MARK: - WKNavigationDelegate
extension BrowserViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        currentURL = webView.url?.absoluteString ?? ""
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Navigation failed: \(error.localizedDescription)")
    }

    // メディア検出時（自動ダウンロードは行わない）
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // URLの拡張子でメディア判定
        if let url = navigationAction.request.url,
           isMediaFile(url: url) {

            // メディアURLを保存してボタン表示
            DispatchQueue.main.async {
                self.detectedMediaURL = url
                self.detectedMediaFileName = url.lastPathComponent
            }
        }

        decisionHandler(.allow)
    }

    private func isMediaFile(url: URL) -> Bool {
        let mediaExtensions = ["mp4", "mov", "avi", "mkv", "webm", "mp3", "wav", "m4a", "flac"]
        let ext = url.pathExtension.lowercased()
        return mediaExtensions.contains(ext)
    }
}

// MARK: - WKScriptMessageHandler
extension BrowserViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "mediaDetected",
           let dict = message.body as? [String: String],
           let urlString = dict["url"],
           let url = URL(string: urlString),
           let fileName = dict["fileName"] {

            DispatchQueue.main.async {
                self.detectedMediaURL = url
                self.detectedMediaFileName = fileName
                print("メディア検出: \(fileName)")
            }
        } else if message.name == "imageLongPress",
                  let dict = message.body as? [String: String],
                  let urlString = dict["url"],
                  let url = URL(string: urlString),
                  let fileName = dict["fileName"] {

            DispatchQueue.main.async {
                print("🖼️ 画像長押し検出: \(fileName)")
                // ダウンロード確認アラートを表示
                self.showImageDownloadAlert(url: url, fileName: fileName)
            }
        }
    }

    private func showImageDownloadAlert(url: URL, fileName: String) {
        // UIAlertControllerを使用してダウンロード確認
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            // アラート表示できない場合は直接ダウンロード
            self.downloadFile(from: url, fileName: fileName)
            return
        }

        let alert = UIAlertController(
            title: "画像をダウンロード",
            message: fileName,
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "ダウンロード", style: .default) { _ in
            self.downloadFile(from: url, fileName: fileName)
        })

        alert.addAction(UIAlertAction(title: "URLをコピー", style: .default) { _ in
            UIPasteboard.general.string = url.absoluteString
        })

        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))

        // iPadの場合はpopoverを設定
        if let popover = alert.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        rootViewController.present(alert, animated: true)
    }
}
