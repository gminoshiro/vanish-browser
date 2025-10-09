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


enum SearchEngine: String, CaseIterable {
    case google = "Google"
    case duckDuckGo = "DuckDuckGo"
    case bing = "Bing"
    case yahoo = "Yahoo! JAPAN"

    var homeURL: String {
        switch self {
        case .google:
            return "https://www.google.com"
        case .duckDuckGo:
            return "https://duckduckgo.com"
        case .bing:
            return "https://www.bing.com"
        case .yahoo:
            return "https://www.yahoo.co.jp"
        }
    }

    func searchURL(query: String) -> String {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        switch self {
        case .google:
            return "https://www.google.com/search?q=\(encoded)"
        case .duckDuckGo:
            return "https://duckduckgo.com/?q=\(encoded)"
        case .bing:
            return "https://www.bing.com/search?q=\(encoded)"
        case .yahoo:
            return "https://search.yahoo.co.jp/search?p=\(encoded)"
        }
    }
}

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

        // JavaScriptで動画にDLボタンを追加するスクリプト
        let mediaDetectionScript = WKUserScript(
            source: """
            function addDownloadButton(video) {
                // 既にボタンが追加されているかチェック
                if (video.dataset.dlButtonAdded) return;
                video.dataset.dlButtonAdded = 'true';

                console.log('🎬 Adding download button to video');

                // ビデオURLを取得
                let videoUrl = video.src || video.currentSrc;
                if (!videoUrl) {
                    const sources = video.querySelectorAll('source');
                    if (sources.length > 0) {
                        videoUrl = sources[0].src;
                    }
                }

                if (!videoUrl || !videoUrl.startsWith('http')) {
                    console.log('⚠️ No valid video URL found');
                    return;
                }

                // DLボタンを作成
                const dlButton = document.createElement('button');
                dlButton.innerHTML = '⬇️ DL';
                dlButton.style.cssText = `
                    position: absolute;
                    bottom: 60px;
                    right: 16px;
                    background: rgba(0, 122, 255, 0.95);
                    color: white;
                    border: none;
                    border-radius: 20px;
                    padding: 10px 20px;
                    font-size: 16px;
                    font-weight: bold;
                    z-index: 999999;
                    cursor: pointer;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.5);
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                `;

                // ボタンクリック時の処理
                dlButton.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    console.log('📥 Download button clicked:', videoUrl);

                    window.webkit.messageHandlers.videoDownload.postMessage({
                        url: videoUrl,
                        fileName: videoUrl.split('/').pop().split('?')[0] || 'video.mp4'
                    });
                });

                // ビデオのコンテナを探す
                let container = video.parentElement;
                while (container && getComputedStyle(container).position === 'static') {
                    container = container.parentElement;
                }

                if (!container) {
                    // コンテナが見つからない場合はvideoをラップ
                    const wrapper = document.createElement('div');
                    wrapper.style.position = 'relative';
                    wrapper.style.display = 'inline-block';
                    video.parentNode.insertBefore(wrapper, video);
                    wrapper.appendChild(video);
                    container = wrapper;
                }

                // ボタンを追加
                container.style.position = 'relative';
                container.appendChild(dlButton);

                console.log('✅ Download button added');
            }

            function detectMedia() {
                const videos = document.querySelectorAll('video');

                videos.forEach(function(video) {
                    // ビデオが再生可能になったらボタンを追加
                    if (video.readyState >= 2) {
                        addDownloadButton(video);
                    } else {
                        video.addEventListener('loadeddata', function() {
                            addDownloadButton(video);
                        }, { once: true });
                    }

                    // フルスクリーン変更時にボタンを再配置
                    video.addEventListener('webkitfullscreenchange', function() {
                        if (document.webkitFullscreenElement === video) {
                            console.log('📺 Fullscreen mode');
                        }
                    });
                });
            }

            // MutationObserverで動的に追加される動画を監視
            const observer = new MutationObserver(function(mutations) {
                detectMedia();
            });

            // ページ読み込み後に監視開始
            if (document.body) {
                observer.observe(document.body, { childList: true, subtree: true });
                detectMedia();
            } else {
                document.addEventListener('DOMContentLoaded', function() {
                    observer.observe(document.body, { childList: true, subtree: true });
                    detectMedia();
                });
            }

            // 定期的にチェック
            setTimeout(detectMedia, 500);
            setTimeout(detectMedia, 1500);
            setTimeout(detectMedia, 3000);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )

        // コンテキストメニュー完全ブロックと画像長押し検出スクリプト
        let imageTapScript = WKUserScript(
            source: """
            (function() {
                console.log('📱 Image tap script loaded');

                // CSSでコンテキストメニューを無効化
                var style = document.createElement('style');
                style.innerHTML = `
                    img, video {
                        -webkit-touch-callout: none !important;
                        -webkit-user-select: none !important;
                    }
                `;
                if (document.head) {
                    document.head.appendChild(style);
                } else {
                    document.addEventListener('DOMContentLoaded', function() {
                        document.head.appendChild(style);
                    });
                }

                // コンテキストメニューをブロック
                function blockContextMenu(e) {
                    if (e.target.tagName === 'IMG' || e.target.tagName === 'VIDEO') {
                        e.preventDefault();
                        e.stopPropagation();
                        return false;
                    }
                }

                document.addEventListener('contextmenu', blockContextMenu, true);

                // 長押し検出
                var longPressTimer = null;
                var touchStartX = 0;
                var touchStartY = 0;
                var hasMoved = false;

                function handleTouchStart(e) {
                    // 画像かどうかチェック
                    var target = e.target;
                    if (!target || target.tagName !== 'IMG') {
                        return;
                    }

                    console.log('🖼️ Image touchstart detected:', target.src);

                    touchStartX = e.touches[0].clientX;
                    touchStartY = e.touches[0].clientY;
                    hasMoved = false;

                    // 長押しタイマー開始
                    longPressTimer = setTimeout(function() {
                        if (!hasMoved) {
                            console.log('⏰ Long press triggered for:', target.src);
                            var imageUrl = target.src || target.currentSrc;

                            if (imageUrl) {
                                try {
                                    window.webkit.messageHandlers.imageLongPress.postMessage({
                                        url: imageUrl,
                                        fileName: imageUrl.split('/').pop().split('?')[0] || 'image.jpg'
                                    });
                                    console.log('✅ Message sent successfully');
                                } catch (err) {
                                    console.error('❌ Error sending message:', err);
                                }
                            }
                        }
                    }, 600);

                    // 画像のデフォルト動作をブロック
                    e.preventDefault();
                }

                function handleTouchMove(e) {
                    if (!longPressTimer) return;

                    var moveX = Math.abs(e.touches[0].clientX - touchStartX);
                    var moveY = Math.abs(e.touches[0].clientY - touchStartY);

                    // 10px以上動いたらキャンセル
                    if (moveX > 10 || moveY > 10) {
                        hasMoved = true;
                        clearTimeout(longPressTimer);
                        longPressTimer = null;
                        console.log('↔️ Touch moved, cancelled');
                    }
                }

                function handleTouchEnd(e) {
                    if (longPressTimer) {
                        clearTimeout(longPressTimer);
                        longPressTimer = null;
                    }
                }

                // イベントリスナー登録
                document.addEventListener('touchstart', handleTouchStart, true);
                document.addEventListener('touchmove', handleTouchMove, true);
                document.addEventListener('touchend', handleTouchEnd, true);
                document.addEventListener('touchcancel', handleTouchEnd, true);

                console.log('✅ Image long press detection ready');
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
        webView.configuration.userContentController.add(self, name: "videoDownload")
        webView.configuration.userContentController.add(self, name: "imageLongPress")
        webView.navigationDelegate = self

        // WebViewの状態を監視
        webView.publisher(for: \.canGoBack)
            .assign(to: &$canGoBack)

        webView.publisher(for: \.canGoForward)
            .assign(to: &$canGoForward)

        webView.publisher(for: \.isLoading)
            .assign(to: &$isLoading)

        // 初期ページをロード（設定された検索エンジン）
        let searchEngineString = UserDefaults.standard.string(forKey: "searchEngine") ?? "Google"
        if let engine = SearchEngine(rawValue: searchEngineString) {
            loadURL(engine.homeURL)
        } else {
            loadURL("https://www.google.com")
        }
    }

    deinit {
        // Message handlerを削除してメモリリークを防ぐ
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoDownload")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "imageLongPress")
    }

    func loadURL(_ urlString: String) {
        var urlToLoad = urlString.trimmingCharacters(in: .whitespaces)

        // URLスキームがない場合は検索と判断
        if !urlToLoad.hasPrefix("http://") && !urlToLoad.hasPrefix("https://") {
            // スペースがあるか、ドメインっぽくない場合は検索
            if urlToLoad.contains(" ") || !urlToLoad.contains(".") {
                // 設定された検索エンジンで検索
                let searchEngineString = UserDefaults.standard.string(forKey: "searchEngine") ?? "Google"
                if let engine = SearchEngine(rawValue: searchEngineString) {
                    urlToLoad = engine.searchURL(query: urlToLoad)
                } else {
                    urlToLoad = "https://www.google.com/search?q=\(urlToLoad.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                }
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
        if message.name == "videoDownload",
           let dict = message.body as? [String: String],
           let urlString = dict["url"],
           let url = URL(string: urlString),
           let fileName = dict["fileName"] {

            DispatchQueue.main.async {
                print("🎬 動画ダウンロード開始: \(fileName)")
                self.downloadFile(from: url, fileName: fileName)
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
