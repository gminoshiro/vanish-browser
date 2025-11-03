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
    @Published var hasVideo = false  // 動画が検出されたか
    @Published var currentVideoURL: URL?  // 現在の動画URL
    @Published var loadError: Error?  // ページ読み込みエラー
    @Published var showToolbars = true  // ツールバー表示状態
    private var videoStoppedTimer: Timer?  // videoStopped遅延用タイマー
    private var lastScrollOffset: CGFloat = 0  // 前回のスクロール位置
    @Published var showErrorAlert = false  // エラーアラート表示フラグ
    @Published var loadingProgress: Double = 0.0  // ページ読み込み進捗（0.0〜1.0）
    @Published var searchMatchCount: Int = 0  // 検索結果のマッチ数
    @Published var currentSearchMatch: Int = 0  // 現在のマッチ位置
    @Published var isReaderMode = false  // リーダーモード
    @Published var readerContent: String = ""  // リーダーモードのコンテンツ
    @Published var isDesktopMode = false  // デスクトップサイト表示

    var webView: WKWebView
    weak var tabManager: TabManager?  // タブマネージャーへの参照（isPrivate取得用）
    private var cancellables = Set<AnyCancellable>()
    private var progressObserver: NSKeyValueObservation?
    private var currentFindConfiguration: WKFindConfiguration?
    private var originalHTML: String = ""

    override init() {
        // 初期ダミーWebView（後でタブのWebViewに置き換え）
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        // メディア再生設定
        configuration.allowsInlineMediaPlayback = true // インライン再生を有効化
        configuration.allowsPictureInPictureMediaPlayback = false // PIPを無効化
        configuration.mediaTypesRequiringUserActionForPlayback = .all // 自動再生を防止

        // カスタムURLスキームハンドラを登録（動画インターセプト用）
        let videoHandler = VideoURLSchemeHandler()
        configuration.setURLSchemeHandler(videoHandler, forURLScheme: "vanish-video")

        // JavaScriptで動画検出（再生中の動画URLを通知）
        let mediaDetectionScript = WKUserScript(
            source: """
            (function() {
                console.log('📱 Media detection script loaded');

                function notifyVideoDetected(video) {
                    try {
                        let videoUrl = video.src || video.currentSrc;
                        if (!videoUrl) {
                            const sources = video.querySelectorAll('source');
                            if (sources.length > 0) {
                                videoUrl = sources[0].src;
                            }
                        }

                        if (videoUrl && videoUrl.startsWith('http')) {
                            console.log('🎬 Video detected:', videoUrl);
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoDetected) {
                                window.webkit.messageHandlers.videoDetected.postMessage({
                                    url: videoUrl,
                                    fileName: videoUrl.split('/').pop().split('?')[0] || 'video.mp4'
                                });
                                console.log('✅ Message sent successfully');
                            } else {
                                console.error('❌ videoDetected handler not found');
                            }
                        } else {
                            console.log('⚠️ No valid video URL found');
                        }
                    } catch (error) {
                        console.error('❌ Error in notifyVideoDetected:', error);
                    }
                }

                function detectVideos() {
                    const videos = document.querySelectorAll('video');
                    console.log('🔍 Checking for videos... Found:', videos.length);
                    let hasPlayableVideo = false;

                    videos.forEach(function(video) {
                        // ビデオが存在し、URLがあり、かつreadyState >= 2（メタデータ読み込み済み）の場合のみDLボタン表示
                        const videoUrl = video.src || video.currentSrc;
                        if (videoUrl && videoUrl.startsWith('http') && video.readyState >= 2) {
                            hasPlayableVideo = true;
                        } else {
                            // sourceタグもチェック
                            const sources = video.querySelectorAll('source');
                            if (sources.length > 0) {
                                const sourceUrl = sources[0].src;
                                if (sourceUrl && sourceUrl.startsWith('http') && video.readyState >= 2) {
                                    hasPlayableVideo = true;
                                }
                            }
                        }

                        if (video.dataset.vanishDetected) return;
                        video.dataset.vanishDetected = 'true';

                        // 動画クリック時にカスタムプレーヤーを起動
                        function handleVideoClick(e) {
                            e.preventDefault();
                            e.stopPropagation();

                            let videoUrl = video.src || video.currentSrc;
                            if (!videoUrl || !videoUrl.startsWith('http')) {
                                const sources = video.querySelectorAll('source');
                                if (sources.length > 0) {
                                    videoUrl = sources[0].src;
                                }
                            }

                            if (videoUrl && videoUrl.startsWith('http')) {
                                console.log('🎬 Video clicked:', videoUrl);
                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoClicked) {
                                    window.webkit.messageHandlers.videoClicked.postMessage({
                                        url: videoUrl,
                                        fileName: videoUrl.split('/').pop().split('?')[0] || 'video.mp4'
                                    });
                                }
                            }
                        }

                        // クリック・タッチイベントをインターセプト
                        video.addEventListener('click', handleVideoClick, true);
                        video.addEventListener('touchend', handleVideoClick, true);

                        // ビデオが読み込まれたら即座に通知
                        if (video.readyState >= 2) {
                            notifyVideoDetected(video);
                        }

                        // 再生を防止してカスタムプレーヤーを起動
                        video.addEventListener('play', function(e) {
                            e.preventDefault();
                            video.pause();

                            let videoUrl = video.src || video.currentSrc;
                            if (!videoUrl || !videoUrl.startsWith('http')) {
                                const sources = video.querySelectorAll('source');
                                if (sources.length > 0) {
                                    videoUrl = sources[0].src;
                                }
                            }

                            if (videoUrl && videoUrl.startsWith('http')) {
                                console.log('🎬 Video play intercepted:', videoUrl);
                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoClicked) {
                                    window.webkit.messageHandlers.videoClicked.postMessage({
                                        url: videoUrl,
                                        fileName: videoUrl.split('/').pop().split('?')[0] || 'video.mp4'
                                    });
                                }
                            }

                            notifyVideoDetected(video);
                        }, true);

                        // loadeddataイベントでも通知
                        video.addEventListener('loadeddata', function() {
                            notifyVideoDetected(video);
                        });

                        // canplayイベントでも通知
                        video.addEventListener('canplay', function() {
                            notifyVideoDetected(video);
                        });

                        // 停止時に通知
                        video.addEventListener('pause', function() {
                            console.log('⏸️ Video paused');
                            // ページに動画がまだある場合はDLボタンを維持
                            setTimeout(detectVideos, 100);
                        });

                        // 終了時に通知
                        video.addEventListener('ended', function() {
                            console.log('⏹️ Video ended');
                            setTimeout(detectVideos, 100);
                        });
                    });

                    // 動画が1つでもあればDLボタンを表示
                    if (hasPlayableVideo) {
                        const firstVideo = videos[0];
                        if (firstVideo) {
                            // 毎回通知して最新の動画URLを更新
                            notifyVideoDetected(firstVideo);
                        }
                    } else if (videos.length === 0) {
                        // 動画がなくなったら停止通知
                        window.webkit.messageHandlers.videoStopped.postMessage({});
                    }
                }

                // 定期的に動画を検出（より頻繁に）
                setInterval(detectVideos, 300);
                detectVideos();

                // DOMContentLoaded後にも実行
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', detectVideos);
                } else {
                    detectVideos();
                }
            })();
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
                    // 画像または動画かどうかチェック
                    var target = e.target;
                    if (!target || (target.tagName !== 'IMG' && target.tagName !== 'VIDEO')) {
                        return;
                    }

                    console.log('🖼️ Media touchstart detected:', target.src);

                    touchStartX = e.touches[0].clientX;
                    touchStartY = e.touches[0].clientY;
                    hasMoved = false;

                    // 長押しタイマー開始
                    longPressTimer = setTimeout(function() {
                        if (!hasMoved) {
                            console.log('⏰ Long press triggered for:', target.src);
                            var mediaUrl = target.src || target.currentSrc;

                            // 動画の場合はsourceタグもチェック
                            if (target.tagName === 'VIDEO' && !mediaUrl) {
                                var sources = target.querySelectorAll('source');
                                if (sources.length > 0) {
                                    mediaUrl = sources[0].src;
                                }
                            }

                            if (mediaUrl) {
                                try {
                                    var isVideo = target.tagName === 'VIDEO';
                                    var handler = isVideo ? 'videoDownload' : 'imageLongPress';
                                    var defaultName = isVideo ? 'video.mp4' : 'image.jpg';

                                    window.webkit.messageHandlers[handler].postMessage({
                                        url: mediaUrl,
                                        fileName: mediaUrl.split('/').pop().split('?')[0] || defaultName
                                    });
                                    console.log('✅ Message sent successfully to', handler);
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

        // blob: URLダウンロード検出スクリプト
        let blobDownloadScript = WKUserScript(
            source: """
            (function() {
                console.log('📦 Blob download detection script loaded');

                // <a>タグのクリックを監視
                document.addEventListener('click', function(e) {
                    var target = e.target;

                    // <a>タグまたはその親要素を探す
                    while (target && target.tagName !== 'A') {
                        target = target.parentElement;
                    }

                    if (!target || target.tagName !== 'A') return;

                    var href = target.href;
                    var download = target.download || target.getAttribute('download');

                    console.log('🔗 Link clicked:', href);
                    console.log('📥 Download attribute:', download);

                    // blob: URLまたはdownload属性付きリンクの場合
                    if (href && (href.startsWith('blob:') || download)) {
                        e.preventDefault();
                        e.stopPropagation();

                        console.log('📦 Blob/Download link detected');

                        var fileName = download || href.split('/').pop() || 'download.zip';

                        // blob: URLの場合、データを取得
                        if (href.startsWith('blob:')) {
                            fetch(href)
                                .then(function(response) {
                                    return response.blob();
                                })
                                .then(function(blob) {
                                    console.log('✅ Blob fetched:', blob.size, 'bytes');

                                    // FileReaderでbase64に変換
                                    var reader = new FileReader();
                                    reader.onloadend = function() {
                                        var base64 = reader.result.split(',')[1];
                                        console.log('✅ Base64 encoded:', base64.length, 'chars');

                                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.blobDownload) {
                                            window.webkit.messageHandlers.blobDownload.postMessage({
                                                url: href,
                                                fileName: fileName,
                                                data: base64,
                                                mimeType: blob.type,
                                                size: blob.size
                                            });
                                            console.log('✅ Blob download message sent');
                                        }
                                    };
                                    reader.readAsDataURL(blob);
                                })
                                .catch(function(error) {
                                    console.error('❌ Blob fetch failed:', error);
                                });
                        } else {
                            // 通常のダウンロードリンク
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.blobDownload) {
                                window.webkit.messageHandlers.blobDownload.postMessage({
                                    url: href,
                                    fileName: fileName
                                });
                            }
                        }

                        return false;
                    }
                }, true);

                console.log('✅ Blob download detection script ready');
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )

        configuration.userContentController.addUserScript(mediaDetectionScript)
        configuration.userContentController.addUserScript(imageTapScript)
        configuration.userContentController.addUserScript(blobDownloadScript)

        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()

        // Message handlerを追加（WebView作成後に追加）
        webView.configuration.userContentController.add(self, name: "videoDownload")
        webView.configuration.userContentController.add(self, name: "imageLongPress")
        webView.configuration.userContentController.add(self, name: "videoDetected")
        webView.configuration.userContentController.add(self, name: "videoStopped")
        webView.configuration.userContentController.add(self, name: "videoClicked")
        webView.configuration.userContentController.add(self, name: "blobDownload")
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // ビデオインターセプターを初期化
        _ = VideoInterceptor.shared

        // WebViewの状態を監視
        webView.publisher(for: \.canGoBack)
            .assign(to: &$canGoBack)

        webView.publisher(for: \.canGoForward)
            .assign(to: &$canGoForward)

        webView.publisher(for: \.isLoading)
            .assign(to: &$isLoading)

        // ページ読み込み進捗を監視
        progressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            DispatchQueue.main.async {
                self?.loadingProgress = change.newValue ?? 0.0
            }
        }

        // ダウンロードプログレス通知を受信
        NotificationCenter.default.addObserver(forName: NSNotification.Name("DownloadProgress"), object: nil, queue: .main) { [weak self] notification in
            if let progress = notification.object as? Float {
                self?.downloadProgress = progress
            }
        }

        // 初期ページは読み込まない（ホーム画面を表示）
        // currentURLを空のままにすることでホーム画面が表示される
    }

    deinit {
        // タイマーを停止
        videoStoppedTimer?.invalidate()

        // Message handlerを削除してメモリリークを防ぐ
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoDownload")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "imageLongPress")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoDetected")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoStopped")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoClicked")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "blobDownload")

        // オブザーバーを解除
        progressObserver?.invalidate()
    }

    func switchWebView(to newWebView: WKWebView) {
        // 古いWebViewのオブザーバーとハンドラーを解除
        progressObserver?.invalidate()
        videoStoppedTimer?.invalidate()
        videoStoppedTimer = nil

        // 古いWebViewのメッセージハンドラーを削除
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoDownload")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "imageLongPress")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoDetected")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoStopped")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "videoClicked")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "blobDownload")

        // 新しいWebViewに切り替え
        webView = newWebView

        // 新しいWebViewにデリゲートとオブザーバーを設定
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // 新しいWebViewにメッセージハンドラーを追加
        webView.configuration.userContentController.add(self, name: "videoDownload")
        webView.configuration.userContentController.add(self, name: "imageLongPress")
        webView.configuration.userContentController.add(self, name: "videoDetected")
        webView.configuration.userContentController.add(self, name: "videoStopped")
        webView.configuration.userContentController.add(self, name: "videoClicked")
        webView.configuration.userContentController.add(self, name: "blobDownload")

        progressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.loadingProgress = webView.estimatedProgress
            }
        }

        // 状態を更新
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        currentURL = webView.url?.absoluteString ?? ""
        isLoading = webView.isLoading
    }

    func loadURL(_ urlString: String) {
        var urlToLoad = urlString.trimmingCharacters(in: .whitespaces)

        // URLスキームがない場合は検索と判断
        if !urlToLoad.hasPrefix("http://") && !urlToLoad.hasPrefix("https://") {
            // スペースがあるか、ドメインっぽくない場合は検索
            if urlToLoad.contains(" ") || !urlToLoad.contains(".") {
                // 設定された検索エンジンで検索
                let searchEngineString = UserDefaults.standard.string(forKey: "searchEngine") ?? "DuckDuckGo"
                if let engine = SearchEngine(rawValue: searchEngineString) {
                    urlToLoad = engine.searchURL(query: urlToLoad)
                } else {
                    urlToLoad = "https://duckduckgo.com/?q=\(urlToLoad.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
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

    // MARK: - ページ内検索
    func searchInPage(_ text: String) {
        guard !text.isEmpty else {
            clearSearch()
            return
        }

        let configuration = WKFindConfiguration()
        configuration.caseSensitive = false
        configuration.wraps = true
        currentFindConfiguration = configuration

        webView.find(text, configuration: configuration) { [weak self] result in
            DispatchQueue.main.async {
                if result.matchFound {
                    // JavaScriptでマッチ数を取得
                    self?.countMatches(text: text)
                    print("🔍 検索結果: \(text) が見つかりました")
                } else {
                    self?.searchMatchCount = 0
                    self?.currentSearchMatch = 0
                    print("🔍 検索結果: \(text) が見つかりませんでした")
                }
            }
        }
    }

    private func countMatches(text: String) {
        let script = """
        var count = 0;
        var selection = window.getSelection();
        var searchText = '\(text.replacingOccurrences(of: "'", with: "\\'"))';
        var bodyText = document.body.innerText || document.body.textContent;
        var regex = new RegExp(searchText, 'gi');
        var matches = bodyText.match(regex);
        matches ? matches.length : 0;
        """

        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let count = result as? Int {
                DispatchQueue.main.async {
                    self?.searchMatchCount = count
                    self?.currentSearchMatch = count > 0 ? 1 : 0
                }
            }
        }
    }

    func findNext() {
        webView.evaluateJavaScript("window.find(null, false, false, true, false, true, false)") { [weak self] _, _ in
            DispatchQueue.main.async {
                if let current = self?.currentSearchMatch, let total = self?.searchMatchCount {
                    self?.currentSearchMatch = current < total ? current + 1 : 1
                }
            }
        }
    }

    func findPrevious() {
        webView.evaluateJavaScript("window.find(null, false, true, true, false, true, false)") { [weak self] _, _ in
            DispatchQueue.main.async {
                if let current = self?.currentSearchMatch {
                    self?.currentSearchMatch = current > 1 ? current - 1 : (self?.searchMatchCount ?? 1)
                }
            }
        }
    }

    func clearSearch() {
        searchMatchCount = 0
        currentSearchMatch = 0
        currentFindConfiguration = nil
        // 検索ハイライトをクリア
        webView.evaluateJavaScript("window.getSelection().removeAllRanges()")
    }

    // MARK: - リーダーモード
    func toggleReaderMode() {
        if isReaderMode {
            // リーダーモード解除
            exitReaderMode()
        } else {
            // リーダーモード有効化
            enterReaderMode()
        }
    }

    private func enterReaderMode() {
        // ページの本文を抽出するJavaScript
        let script = """
        (function() {
            // タイトル取得
            let title = document.title || document.querySelector('h1')?.textContent || '';

            // メインコンテンツ抽出（複数の方法を試す）
            let content = '';

            // article タグを優先
            let article = document.querySelector('article');
            if (article) {
                content = article.innerHTML;
            } else {
                // main タグを試す
                let main = document.querySelector('main');
                if (main) {
                    content = main.innerHTML;
                } else {
                    // role="main" を試す
                    let roleMain = document.querySelector('[role="main"]');
                    if (roleMain) {
                        content = roleMain.innerHTML;
                    } else {
                        // 最後の手段：p タグを集める
                        let paragraphs = document.querySelectorAll('p');
                        if (paragraphs.length > 0) {
                            content = Array.from(paragraphs).map(p => p.outerHTML).join('');
                        }
                    }
                }
            }

            // 不要な要素を削除
            let tempDiv = document.createElement('div');
            tempDiv.innerHTML = content;
            tempDiv.querySelectorAll('script, style, nav, aside, footer, header, .ad, .advertisement, .social-share').forEach(el => el.remove());

            return {
                title: title,
                content: tempDiv.innerHTML
            };
        })();
        """

        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let error = error {
                print("❌ リーダーモード取得エラー: \(error)")
                return
            }

            if let dict = result as? [String: String],
               let title = dict["title"],
               let content = dict["content"] {
                DispatchQueue.main.async {
                    self?.readerContent = """
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <style>
                            body {
                                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                                line-height: 1.8;
                                max-width: 700px;
                                margin: 0 auto;
                                padding: 20px;
                                background: #f9f9f9;
                                color: #333;
                            }
                            h1 {
                                font-size: 28px;
                                margin-bottom: 20px;
                                color: #000;
                            }
                            p {
                                font-size: 18px;
                                margin-bottom: 16px;
                            }
                            img {
                                max-width: 100%;
                                height: auto;
                                border-radius: 8px;
                                margin: 20px 0;
                            }
                            a {
                                color: #007AFF;
                                text-decoration: none;
                            }
                        </style>
                    </head>
                    <body>
                        <h1>\(title)</h1>
                        \(content)
                    </body>
                    </html>
                    """
                    self?.isReaderMode = true
                    print("✅ リーダーモード有効化")
                }
            }
        }
    }

    private func exitReaderMode() {
        isReaderMode = false
        readerContent = ""
        print("✅ リーダーモード解除")
    }

    // MARK: - デスクトップサイト表示
    func toggleDesktopMode() {
        isDesktopMode.toggle()

        // User-Agentを変更
        let desktopUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        let mobileUA = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        webView.customUserAgent = isDesktopMode ? desktopUA : mobileUA

        // ページをリロード
        webView.reload()

        print("✅ デスクトップモード: \(isDesktopMode ? "有効" : "無効")")
    }
}

// MARK: - WKNavigationDelegate
extension BrowserViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.currentURL = webView.url?.absoluteString ?? ""
            self.isLoading = false
            self.loadingProgress = 0.0

            // 閲覧履歴に追加（プライベートモードの場合は保存しない）
            if let url = webView.url?.absoluteString,
               !url.isEmpty,
               !url.hasPrefix("about:"),
               !url.hasPrefix("file:") {
                let title = webView.title ?? url
                let isPrivate = self.tabManager?.currentTab?.isPrivate ?? false
                BrowsingHistoryManager.shared.addToHistory(url: url, title: title, isPrivate: isPrivate)
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Navigation failed: \(error.localizedDescription)")

        // エラー -999 はナビゲーションがキャンセルされただけなので無視
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            print("ℹ️ Navigation cancelled (expected behavior)")
            DispatchQueue.main.async {
                self.isLoading = false
                self.loadingProgress = 0.0
            }
            return
        }

        DispatchQueue.main.async {
            self.loadError = error
            self.showErrorAlert = true
            self.isLoading = false
            self.loadingProgress = 0.0
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Provisional navigation failed: \(error.localizedDescription)")

        // エラー -999 はナビゲーションがキャンセルされただけなので無視
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            print("ℹ️ Provisional navigation cancelled (expected behavior)")
            DispatchQueue.main.async {
                self.isLoading = false
                self.loadingProgress = 0.0
            }
            return
        }

        DispatchQueue.main.async {
            self.loadError = error
            self.showErrorAlert = true
            self.isLoading = false
            self.loadingProgress = 0.0
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.loadError = nil
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
    }

    // メディア検出時（自動ダウンロードは行わない）
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // URLの拡張子で判定
        if let url = navigationAction.request.url {
            // blob: URLへのナビゲーションをブロック（文字化けページ表示を防ぐ）
            if url.scheme == "blob" {
                print("🚫 blob: URL navigation blocked: \(url.absoluteString)")

                // JavaScriptでblob:データを取得してダウンロード
                let urlString = url.absoluteString.replacingOccurrences(of: "'", with: "\\'")
                let js = """
                (function() {
                    var blobUrl = '\(urlString)';
                    console.log('📦 Fetching blob:', blobUrl);

                    fetch(blobUrl)
                        .then(function(response) { return response.blob(); })
                        .then(function(blob) {
                            console.log('✅ Blob fetched:', blob.size, 'bytes');

                            var reader = new FileReader();
                            reader.onloadend = function() {
                                var base64 = reader.result.split(',')[1];

                                // ファイル名を推測（拡張子から）
                                var fileName = 'download.zip';
                                if (blob.type.includes('zip')) fileName = 'archive.zip';
                                else if (blob.type.includes('pdf')) fileName = 'document.pdf';
                                else if (blob.type.includes('image')) fileName = 'image.' + blob.type.split('/')[1];

                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.blobDownload) {
                                    window.webkit.messageHandlers.blobDownload.postMessage({
                                        url: blobUrl,
                                        fileName: fileName,
                                        data: base64,
                                        mimeType: blob.type,
                                        size: blob.size
                                    });
                                    console.log('✅ Blob download message sent');
                                }
                            };
                            reader.readAsDataURL(blob);
                        })
                        .catch(function(error) {
                            console.error('❌ Blob fetch failed:', error);
                        });
                })();
                """

                webView.evaluateJavaScript(js) { result, error in
                    if let error = error {
                        print("❌ JavaScript execution failed: \(error)")
                    }
                }

                decisionHandler(.cancel)
                return
            }

            // ZIPファイルまたは画像ファイルの場合はダウンロードダイアログを表示
            if isDownloadableFile(url: url) {
                print("📦 ダウンロード可能なファイル検出: \(url.lastPathComponent)")

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowDownloadDialog"),
                        object: nil,
                        userInfo: [
                            "url": url,
                            "fileName": url.lastPathComponent
                        ]
                    )
                }

                decisionHandler(.cancel)
                return
            }

            // 動画・音声ファイルの場合はカスタムプレーヤーを起動
            if isMediaFile(url: url) {
                print("🎬 動画ファイルへのナビゲーション検出: \(url.lastPathComponent)")

                // メディアURLを保存してボタン表示
                DispatchQueue.main.async {
                    self.detectedMediaURL = url
                    self.detectedMediaFileName = url.lastPathComponent

                    // カスタムプレーヤーを直接起動
                    print("🎬 カスタムプレーヤーを起動: \(url.lastPathComponent)")
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

                // 標準プレーヤーでの再生をキャンセル
                print("✅ 標準ナビゲーションをキャンセル")
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    private func isMediaFile(url: URL) -> Bool {
        let mediaExtensions = ["mp4", "mov", "avi", "mkv", "webm", "mp3", "wav", "m4a", "flac"]
        let ext = url.pathExtension.lowercased()
        return mediaExtensions.contains(ext)
    }

    private func isDownloadableFile(url: URL) -> Bool {
        let downloadableExtensions = [
            "zip", "rar", "7z"  // アーカイブのみ（画像・PDFは通常表示）
        ]
        let ext = url.pathExtension.lowercased()
        return downloadableExtensions.contains(ext)
    }

    // レスポンスヘッダーでダウンロード判定（Content-Typeなど）
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let response = navigationResponse.response as? HTTPURLResponse,
              let url = response.url else {
            decisionHandler(.allow)
            return
        }

        // Content-Typeでダウンロード判定
        let contentType = response.allHeaderFields["Content-Type"] as? String ?? ""
        let isAttachment = (response.allHeaderFields["Content-Disposition"] as? String ?? "").contains("attachment")

        // ZIPファイルまたはアーカイブファイルの場合
        let isArchive = contentType.contains("zip") ||
                       contentType.contains("x-rar") ||
                       contentType.contains("x-7z") ||
                       isDownloadableFile(url: url)

        if isArchive || isAttachment {
            print("📦 ダウンロード可能なファイル検出（レスポンス）: \(url.lastPathComponent)")
            print("   Content-Type: \(contentType)")

            // iOS 14.5+の場合はWKDownloadを使用
            if #available(iOS 14.5, *) {
                print("✅ WKDownloadを開始します")
                decisionHandler(.download)
                return
            }

            // iOS 14.5未満の場合は従来の方法
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowDownloadDialog"),
                    object: nil,
                    userInfo: [
                        "url": url,
                        "fileName": url.lastPathComponent
                    ]
                )
            }

            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    // iOS 14.5+: navigationResponseがダウンロードになった時
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        print("📦 WKDownload開始: \(download)")
        download.delegate = self
    }

    // iOS 14.5+: navigationActionがダウンロードになった時
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        print("📦 WKDownload開始（navigationAction）: \(download)")
        download.delegate = self
    }
}

// MARK: - WKDownloadDelegate
@available(iOS 14.5, *)
extension BrowserViewModel: WKDownloadDelegate {
    // ダウンロード開始時の保存先を決定
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        print("📦 ダウンロード保存先決定: \(suggestedFilename)")

        // 一時ディレクトリに保存
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent(suggestedFilename)

        // 既存ファイルを削除
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        print("✅ 保存先: \(destinationURL.path)")
        completionHandler(destinationURL)
    }

    // ダウンロード完了
    func downloadDidFinish(_ download: WKDownload) {
        print("✅ ダウンロード完了")

        // ダウンロードダイアログを表示
        if let originalURL = download.originalRequest?.url {
            let fileName = originalURL.lastPathComponent
            print("📦 ダウンロード完了ダイアログ表示: \(fileName)")

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowDownloadDialog"),
                    object: nil,
                    userInfo: [
                        "url": originalURL,
                        "fileName": fileName
                    ]
                )
            }
        }
    }

    // ダウンロード失敗
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        print("❌ ダウンロード失敗: \(error.localizedDescription)")

        DispatchQueue.main.async {
            self.loadError = error
            self.showErrorAlert = true
        }
    }
}

// MARK: - WKScriptMessageHandler
extension BrowserViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "videoDetected",
           let dict = message.body as? [String: String],
           let urlString = dict["url"],
           let url = URL(string: urlString),
           let fileName = dict["fileName"] {

            DispatchQueue.main.async {
                // URLが変わった時だけログ出力
                if self.currentVideoURL?.absoluteString != urlString {
                    print("🎬 動画検出: \(fileName) - URL: \(urlString)")
                }

                // videoStoppedタイマーをキャンセル（動画が再検出された）
                self.videoStoppedTimer?.invalidate()
                self.videoStoppedTimer = nil

                self.hasVideo = true
                self.currentVideoURL = url
                self.detectedMediaFileName = fileName
            }
        } else if message.name == "videoStopped" {
            // videoStoppedは頻繁に発火するので、2秒遅延させて安定化
            DispatchQueue.main.async {
                // 既存のタイマーをキャンセル
                self.videoStoppedTimer?.invalidate()

                // 2秒後にhasVideoをfalseにする
                self.videoStoppedTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    print("⏸️ 動画停止（2秒後）")
                    self?.hasVideo = false
                    self?.currentVideoURL = nil
                    self?.videoStoppedTimer = nil
                }
            }
        } else if message.name == "videoClicked",
           let dict = message.body as? [String: String],
           let urlString = dict["url"],
           let url = URL(string: urlString),
           let fileName = dict["fileName"] {

            DispatchQueue.main.async {
                print("🎬 動画クリック検出: \(fileName)")
                // カスタムプレーヤーを表示
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowCustomVideoPlayer"),
                    object: nil,
                    userInfo: [
                        "url": url,
                        "fileName": fileName
                    ]
                )
            }
        } else if message.name == "videoDownload",
           let dict = message.body as? [String: String],
           let urlString = dict["url"],
           let url = URL(string: urlString),
           let fileName = dict["fileName"] {

            DispatchQueue.main.async {
                print("🎬 動画長押し検出: \(fileName)")
                // メニューを表示するための通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowMediaMenu"),
                    object: nil,
                    userInfo: ["url": url, "fileName": fileName, "type": "video"]
                )
            }
        } else if message.name == "imageLongPress",
                  let dict = message.body as? [String: String],
                  let urlString = dict["url"],
                  let url = URL(string: urlString),
                  let fileName = dict["fileName"] {

            DispatchQueue.main.async {
                print("🖼️ 画像長押し検出: \(fileName)")
                // メニューを表示するための通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowMediaMenu"),
                    object: nil,
                    userInfo: ["url": url, "fileName": fileName, "type": "image"]
                )
            }
        } else if message.name == "blobDownload",
                  let dict = message.body as? [String: Any],
                  let fileName = dict["fileName"] as? String {

            DispatchQueue.main.async {
                print("📦 Blob download detected: \(fileName)")

                // blob: URLの場合はbase64データがある
                if let base64Data = dict["data"] as? String,
                   let data = Data(base64Encoded: base64Data) {

                    print("✅ Blob data received: \(data.count) bytes")

                    // 一時ファイルに保存
                    let tempDir = FileManager.default.temporaryDirectory
                    let tempFile = tempDir.appendingPathComponent(fileName)

                    do {
                        try data.write(to: tempFile)
                        print("✅ Blob saved to temp file: \(tempFile.path)")

                        // ダウンロードダイアログを表示
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ShowDownloadDialog"),
                            object: nil,
                            userInfo: [
                                "url": tempFile,
                                "fileName": fileName
                            ]
                        )
                    } catch {
                        print("❌ Failed to save blob: \(error)")
                    }
                } else if let urlString = dict["url"] as? String,
                          let url = URL(string: urlString) {
                    // 通常のダウンロードリンク
                    print("📦 Download link detected: \(urlString)")

                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowDownloadDialog"),
                        object: nil,
                        userInfo: [
                            "url": url,
                            "fileName": fileName
                        ]
                    )
                }
            }
        }
    }
}

// MARK: - WKUIDelegate
extension BrowserViewModel: WKUIDelegate {
    // 動画のフルスクリーン再生要求を横取り
    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping (UIContextMenuConfiguration?) -> Void
    ) {
        // 動画要素の場合、カスタムメニューを表示
        if let url = elementInfo.linkURL, isVideoURL(url) {
            let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                let downloadAction = UIAction(title: "動画をダウンロード", image: UIImage(systemName: "arrow.down.circle")) { _ in
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowVideoDownloadPrompt"),
                        object: nil,
                        userInfo: ["url": url, "fileName": url.lastPathComponent]
                    )
                }
                return UIMenu(title: "", children: [downloadAction])
            }
            completionHandler(config)
        } else {
            completionHandler(nil)
        }
    }

    // フルスクリーン再生の開始を防止
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // 新しいウィンドウでの動画再生を防止
        print("🚫 新しいウィンドウ作成をブロック")

        // 動画URLの場合はカスタムプレーヤーを表示
        if let url = navigationAction.request.url, isVideoURL(url) {
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

        return nil
    }

    private func isVideoURL(_ url: URL) -> Bool {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm", "m3u8"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }

    // iPad判定
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    // スクロール検出でツールバー表示/非表示を制御
    func handleScroll(offset: CGFloat) {
        // iPadの場合はスクロールでバーを隠さない
        if isIPad {
            showToolbars = true
            return
        }

        // iPhone: スクロール連動でバー表示/非表示
        let threshold: CGFloat = 10
        let delta = offset - lastScrollOffset

        // 下スクロール（コンテンツが上に移動）= ツールバーを隠す
        if delta > threshold && showToolbars {
            DispatchQueue.main.async {
                self.showToolbars = false
            }
        }
        // 上スクロール（コンテンツが下に移動）= ツールバーを表示
        else if delta < -threshold && !showToolbars {
            DispatchQueue.main.async {
                self.showToolbars = true
            }
        }

        lastScrollOffset = offset
    }
}
