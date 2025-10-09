//
//  BrowserViewModel.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import Foundation
import WebKit
import Combine

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

        configuration.userContentController.addUserScript(mediaDetectionScript)

        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()

        webView.navigationDelegate = self
        configuration.userContentController.add(self, name: "mediaDetected")

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
        }
    }
}
