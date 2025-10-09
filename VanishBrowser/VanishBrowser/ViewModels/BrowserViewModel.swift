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

    let webView: WKWebView
    private var cancellables = Set<AnyCancellable>()

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent() // プライバシー保護：永続化しない

        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()

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

    // ダウンロード開始時
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // URLの拡張子でダウンロード判定
        if let url = navigationAction.request.url,
           shouldDownloadByExtension(url: url) {

            let fileName = url.lastPathComponent
            downloadFile(from: url, fileName: fileName)
            decisionHandler(.cancel)
            return
        }

        // Content-Typeでもチェック
        if let url = navigationAction.request.url,
           let mimeType = navigationAction.request.value(forHTTPHeaderField: "Content-Type"),
           shouldDownloadByMimeType(mimeType: mimeType) {

            let fileName = url.lastPathComponent
            downloadFile(from: url, fileName: fileName)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    private func shouldDownloadByExtension(url: URL) -> Bool {
        let downloadableExtensions = ["pdf", "zip", "mp4", "mov", "avi", "mkv", "mp3", "wav", "m4a", "jpg", "jpeg", "png", "gif", "webp"]
        let ext = url.pathExtension.lowercased()
        return downloadableExtensions.contains(ext)
    }

    private func shouldDownloadByMimeType(mimeType: String) -> Bool {
        let downloadableTypes = ["application/pdf", "application/zip", "image/", "video/", "audio/"]
        return downloadableTypes.contains { mimeType.hasPrefix($0) }
    }
}
