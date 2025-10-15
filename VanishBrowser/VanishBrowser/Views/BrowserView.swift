//
//  BrowserView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI
import WebKit

struct BrowserView: View {
    @StateObject private var tabManager = TabManager()
    @StateObject private var viewModel = BrowserViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var urlText: String = ""
    @State private var showBookmarks = false
    @State private var showDownloads = false
    @State private var showSettings = false
    @State private var isBookmarked = false
    @State private var showTabBar = false
    @State private var showTabManager = false
    @State private var showDownloadDialog = false
    @State private var pendingDownloadURL: URL?
    @State private var pendingDownloadFileName: String = ""
    @State private var showMediaMenu = false
    @State private var mediaMenuURL: URL?
    @State private var mediaMenuFileName: String = ""
    @State private var mediaMenuType: String = ""
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showPageSearch = false
    @State private var pageSearchText = ""
    @State private var showCookieManager = false
    @State private var showBrowsingHistory = false
    @State private var showVideoPrompt = false
    @State private var videoPromptURL: URL?
    @State private var videoPromptFileName: String = ""
    @State private var showCustomVideoPlayer = false
    @State private var customVideoURL: URL?
    @State private var customVideoFileName: String = ""
    @State private var showDownloadCompleted = false
    @State private var downloadedFileName = ""
    @State private var downloadedFileSize: Int64 = 0
    @State private var showBookmarkFolderSelection = false
    @State private var pendingBookmarkTitle = ""
    @State private var pendingBookmarkURL = ""
    @State private var selectedBookmarkFolder = ""

    var body: some View {
        VStack(spacing: 0) {
            // オフライン通知バー
            if !networkMonitor.isConnected {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("オフライン")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.orange)
                .foregroundColor(.white)
                .transition(.move(edge: .top))
            }

            // タブバー（トグルで表示/非表示）
            if showTabBar {
                TabBarView(tabManager: tabManager)
                    .transition(.move(edge: .top))
            }

            // URLバー
            HStack {
                // タブボタン
                Button(action: {
                    showTabManager = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.on.square")
                        Text("\(tabManager.activeTabs.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }

                TextField("URLを入力またはキーワード検索", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onSubmit {
                        viewModel.loadURL(urlText)
                        if let tabId = tabManager.currentTabId {
                            tabManager.updateTab(tabId, url: urlText)
                        }
                    }

                Button(action: {
                    viewModel.loadURL(urlText)
                    if let tabId = tabManager.currentTabId {
                        tabManager.updateTab(tabId, url: urlText)
                    }
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                }
            }
            .padding()

            // ページ読み込みプログレスバー
            if viewModel.loadingProgress > 0 && viewModel.loadingProgress < 1.0 {
                ProgressView(value: viewModel.loadingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 2)
            }

            // ページ内検索バー
            if showPageSearch {
                PageSearchView(
                    searchText: $pageSearchText,
                    isSearching: $showPageSearch,
                    currentMatch: viewModel.currentSearchMatch,
                    totalMatches: viewModel.searchMatchCount,
                    onNext: {
                        viewModel.findNext()
                    },
                    onPrevious: {
                        viewModel.findPrevious()
                    },
                    onDone: {
                        showPageSearch = false
                        pageSearchText = ""
                        viewModel.clearSearch()
                    }
                )
                .transition(.move(edge: .top))
            }

            // WebView
            // ダウンロードプログレス表示
            ZStack {
                // 通常のWebViewまたはリーダーモード
                if viewModel.isReaderMode {
                    ReaderModeView(htmlContent: viewModel.readerContent)
                        .transition(.opacity)
                } else {
                    WebView(viewModel: viewModel, tabManager: tabManager)
                }

                // エラーページ表示
                if viewModel.showErrorAlert, let error = viewModel.loadError {
                    ErrorPageView(
                        error: error,
                        url: viewModel.currentURL,
                        onRetry: {
                            viewModel.showErrorAlert = false
                            viewModel.reload()
                        },
                        onGoBack: {
                            viewModel.showErrorAlert = false
                            if viewModel.canGoBack {
                                viewModel.goBack()
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }

                // ローディングインジケーター
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }

                // 動画再生中のDLボタン（オーバーレイ） - フルスクリーン対策で常に最前面
                if viewModel.hasVideo {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action: {
                                if let videoURL = viewModel.currentVideoURL,
                                   let fileName = viewModel.detectedMediaFileName {
                                    pendingDownloadURL = videoURL
                                    pendingDownloadFileName = fileName
                                    showDownloadDialog = true
                                }
                            }) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                            .frame(width: 50, height: 50)
                                    )
                            }
                            .padding(.leading, 20)
                            .padding(.bottom, 100)
                            .zIndex(999) // 最前面に表示

                            Spacer()
                        }
                    }
                    .allowsHitTesting(true)
                    .zIndex(999)
                }

                if viewModel.isDownloading {
                    VStack {
                        Spacer()
                        DownloadProgressView(
                            fileName: viewModel.detectedMediaFileName ?? "ダウンロード中...",
                            progress: Double(viewModel.downloadProgress)
                        )
                        .padding(.bottom, 80)
                    }
                    .transition(.move(edge: .bottom))
                }
            }

            // ツールバー
            HStack(spacing: 8) {
                // 動画再生中はDLボタンを左端に追加
                if viewModel.hasVideo {
                    Button(action: {
                        if let videoURL = viewModel.currentVideoURL,
                           let fileName = viewModel.detectedMediaFileName {
                            pendingDownloadURL = videoURL
                            pendingDownloadFileName = fileName
                            showDownloadDialog = true
                        }
                    }) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                            .frame(minWidth: 40, minHeight: 40)
                    }
                }

                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                        .frame(minWidth: 40, minHeight: 40)
                }
                .disabled(!viewModel.canGoBack)

                Button(action: { viewModel.goForward() }) {
                    Image(systemName: "chevron.right")
                        .frame(minWidth: 40, minHeight: 40)
                }
                .disabled(!viewModel.canGoForward)

                Button(action: { viewModel.reload() }) {
                    Image(systemName: "arrow.clockwise")
                        .frame(minWidth: 40, minHeight: 40)
                }

                Spacer()

                Button(action: {
                    toggleBookmark()
                }) {
                    Image(systemName: isBookmarked ? "book.fill" : "book")
                        .foregroundColor(isBookmarked ? .blue : .primary)
                        .frame(minWidth: 40, minHeight: 40)
                }

                Button(action: {
                    showBrowsingHistory = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .frame(minWidth: 40, minHeight: 40)
                }

                Button(action: {
                    showDownloads = true
                }) {
                    Image(systemName: "arrow.down.circle")
                        .frame(minWidth: 40, minHeight: 40)
                }

                Menu {
                    Button(action: {
                        showPageSearch.toggle()
                    }) {
                        Label("ページ内検索", systemImage: "magnifyingglass")
                    }

                    Button(action: {
                        withAnimation {
                            viewModel.toggleReaderMode()
                        }
                    }) {
                        Label(
                            viewModel.isReaderMode ? "リーダーモード: ON" : "リーダーモード",
                            systemImage: viewModel.isReaderMode ? "doc.text.fill" : "doc.plaintext"
                        )
                    }

                    Divider()

                    Button(action: {
                        viewModel.toggleDesktopMode()
                    }) {
                        Label(
                            viewModel.isDesktopMode ? "モバイルサイト" : "デスクトップサイト",
                            systemImage: viewModel.isDesktopMode ? "iphone" : "desktopcomputer"
                        )
                    }

                    Button(action: {
                        showCookieManager = true
                    }) {
                        Label("Cookie管理", systemImage: "folder.badge.gearshape")
                    }

                    Divider()

                    Button(action: {
                        showSettings = true
                    }) {
                        Label("設定", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .frame(minWidth: 40, minHeight: 40)
                }
            }
            .font(.title3)
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .onChange(of: viewModel.currentURL) { _, newURL in
            urlText = newURL
            updateBookmarkStatus()

            // タブのURLを更新
            if let tabId = tabManager.currentTabId {
                tabManager.updateTab(tabId, url: newURL)
            }
        }
        .onChange(of: viewModel.webView.title) { _, newTitle in
            // タブのタイトルを更新
            if let title = newTitle, let tabId = tabManager.currentTabId {
                tabManager.updateTab(tabId, title: title)
            }
        }
        .onChange(of: tabManager.currentTabId) { oldTabId, newTabId in
            // 前のタブのスナップショットを取得
            if let oldId = oldTabId {
                captureSnapshot(for: oldId)
            }

            // タブが切り替わったらそのタブのURLをロード
            if let tab = tabManager.currentTab {
                if !tab.url.isEmpty {
                    viewModel.loadURL(tab.url)
                    urlText = tab.url
                } else {
                    // 新規タブの場合は初期ページ（検索エンジン）をロード
                    let searchEngineString = UserDefaults.standard.string(forKey: "searchEngine") ?? "Google"
                    if let engine = SearchEngine(rawValue: searchEngineString) {
                        viewModel.loadURL(engine.homeURL)
                    } else {
                        viewModel.loadURL("https://www.google.com")
                    }
                    urlText = ""
                }
            }
        }
        .onChange(of: pageSearchText) { _, newText in
            // 検索テキストが変更されたら検索実行
            viewModel.searchInPage(newText)
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarkListView(onSelectBookmark: { url in
                viewModel.loadURL(url)
            })
        }
        .sheet(isPresented: $showDownloads) {
            DownloadListView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showCookieManager) {
            CookieManagerView()
        }
        .sheet(isPresented: $showBrowsingHistory) {
            BrowsingHistoryView(onSelectURL: { url in
                viewModel.loadURL(url)
            })
        }
        .sheet(isPresented: $showDownloadDialog) {
            downloadDialogView
        }
        .sheet(isPresented: $showBookmarkFolderSelection) {
            BookmarkFolderSelectionView(
                bookmarkTitle: pendingBookmarkTitle,
                bookmarkURL: pendingBookmarkURL,
                selectedFolder: $selectedBookmarkFolder,
                onSave: {
                    BookmarkService.shared.addBookmark(
                        title: pendingBookmarkTitle,
                        url: pendingBookmarkURL,
                        folder: selectedBookmarkFolder
                    )
                    isBookmarked = true
                    showBookmarkFolderSelection = false
                }
            )
        }
        .fullScreenCover(isPresented: $showTabManager) {
            TabManagerView(tabManager: tabManager)
        }
        .confirmationDialog("", isPresented: $showMediaMenu, titleVisibility: .hidden) {
            Button(mediaMenuType == "video" ? "動画をダウンロード" : "画像をダウンロード") {
                if let url = mediaMenuURL {
                    pendingDownloadURL = url
                    pendingDownloadFileName = mediaMenuFileName
                    showDownloadDialog = true
                }
            }
            Button("URLをコピー") {
                if let url = mediaMenuURL {
                    UIPasteboard.general.string = url.absoluteString
                }
            }
            Button("リンクをシェア") {
                if let url = mediaMenuURL {
                    shareItems = [url]
                    showShareSheet = true
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text(mediaMenuFileName)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("動画を検出しました", isPresented: $showVideoPrompt) {
            Button("ダウンロード") {
                if let url = videoPromptURL {
                    pendingDownloadURL = url
                    pendingDownloadFileName = videoPromptFileName
                    showDownloadDialog = true
                }
            }
            Button("再生") {
                // カスタムプレーヤーで再生
                if let url = videoPromptURL {
                    customVideoURL = url
                    customVideoFileName = videoPromptFileName
                    showCustomVideoPlayer = true

                    // 動画に承認フラグをセット
                    let script = """
                    (function() {
                        const videos = document.querySelectorAll('video');
                        videos.forEach(function(video) {
                            video.dataset.vanishApproved = 'true';
                        });
                    })();
                    """
                    viewModel.webView.evaluateJavaScript(script, completionHandler: nil)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text(videoPromptFileName)
        }
        .fullScreenCover(isPresented: $showCustomVideoPlayer) {
            if let url = customVideoURL {
                CustomVideoPlayerView(
                    videoURL: url,
                    videoFileName: customVideoFileName,
                    showDownloadButton: true,  // DL前の動画なのでDLボタンあり
                    isPresented: $showCustomVideoPlayer
                )
            }
        }
        .alert("ダウンロード完了", isPresented: $showDownloadCompleted) {
            Button("ダウンロードを見る") {
                showDownloads = true
            }
            Button("OK", role: .cancel) {}
        } message: {
            let sizeInMB = Double(downloadedFileSize) / 1_048_576
            Text("\(downloadedFileName)\n(\(String(format: "%.1f", sizeInMB)) MB)")
        }
        .onAppear {
            // ダウンロードダイアログ表示の通知を受信
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowDownloadDialog"),
                object: nil,
                queue: .main
            ) { notification in
                print("📨 ShowDownloadDialog通知受信")
                if let userInfo = notification.userInfo,
                   let url = userInfo["url"] as? URL,
                   let fileName = userInfo["fileName"] as? String {
                    print("📨 URL: \(url.absoluteString), fileName: \(fileName)")
                    pendingDownloadURL = url
                    pendingDownloadFileName = fileName
                    showDownloadDialog = true
                    print("📨 showDownloadDialog = true に設定")
                } else {
                    print("❌ userInfo が nil または不正")
                }
            }

            // メディアメニュー表示の通知を受信
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowMediaMenu"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let url = userInfo["url"] as? URL,
                   let fileName = userInfo["fileName"] as? String,
                   let type = userInfo["type"] as? String {
                    mediaMenuURL = url
                    mediaMenuFileName = fileName
                    mediaMenuType = type
                    showMediaMenu = true
                }
            }

            // タブ複製の通知を受信
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("DuplicateTab"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let url = userInfo["url"] as? String {
                    tabManager.createNewTab(url: url)
                }
            }

            // 動画クリック時のダウンロード確認通知を受信
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowVideoDownloadPrompt"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let url = userInfo["url"] as? URL,
                   let fileName = userInfo["fileName"] as? String {
                    videoPromptURL = url
                    videoPromptFileName = fileName
                    showVideoPrompt = true
                }
            }

            // 動画リクエストインターセプト通知を受信
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("VideoRequestIntercepted"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let urlString = userInfo["url"] as? String,
                   let url = URL(string: urlString),
                   let fileName = userInfo["fileName"] as? String {
                    videoPromptURL = url
                    videoPromptFileName = fileName
                    showVideoPrompt = true
                }
            }

            // ダウンロード完了通知を受信
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("DownloadCompleted"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let fileName = userInfo["fileName"] as? String,
                   let fileSize = userInfo["fileSize"] as? Int64 {
                    downloadedFileName = fileName
                    downloadedFileSize = fileSize
                    showDownloadCompleted = true
                }
            }

            // カスタムビデオプレーヤー表示通知を受信
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowCustomVideoPlayer"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let url = userInfo["url"] as? URL,
                   let fileName = userInfo["fileName"] as? String {
                    customVideoURL = url
                    customVideoFileName = fileName
                    showCustomVideoPlayer = true
                }
            }
        }
    }

    private func toggleBookmark() {
        guard let url = viewModel.webView.url?.absoluteString,
              let title = viewModel.webView.title else { return }

        if isBookmarked {
            // 削除処理は一覧から行う
            showBookmarks = true
        } else {
            // フォルダ選択ダイアログを表示
            pendingBookmarkTitle = title
            pendingBookmarkURL = url
            showBookmarkFolderSelection = true
        }
    }

    private func updateBookmarkStatus() {
        guard let url = viewModel.webView.url?.absoluteString else {
            isBookmarked = false
            return
        }
        isBookmarked = BookmarkService.shared.isBookmarked(url: url)
    }

    private func captureSnapshot(for tabId: UUID) {
        let config = WKSnapshotConfiguration()
        config.snapshotWidth = 300 as NSNumber  // サムネイルサイズ

        viewModel.webView.takeSnapshot(with: config) { image, error in
            if let error = error {
                print("❌ スナップショット取得エラー: \(error)")
                return
            }

            if let image = image {
                // 画像を圧縮してメモリを節約
                if let compressedData = image.jpegData(compressionQuality: 0.5),
                   let compressedImage = UIImage(data: compressedData) {
                    DispatchQueue.main.async {
                        self.tabManager.updateTab(tabId, snapshot: compressedImage)
                        print("✅ スナップショット保存成功: \(tabId)")
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private var downloadDialogView: some View {
        if let url = pendingDownloadURL {
            DownloadDialogView(
                fileName: $pendingDownloadFileName,
                videoURL: url,
                onDownload: handleNormalDownload,
                onHLSDownload: handleHLSDownload
            )
        }
    }

    // MARK: - Helper Functions

    private func handleNormalDownload(fileName: String, folder: String) {
        guard let url = pendingDownloadURL else { return }
        DownloadManager.shared.startDownload(url: url, fileName: fileName, folder: folder)
        print("✅ ダウンロード開始: \(folder)/\(fileName)")
    }

    private func handleHLSDownload(quality: HLSQuality, fileName: String, folder: String) {
        Task {
            let hlsDownloader = HLSDownloader()
            do {
                let m3u8File = try await hlsDownloader.downloadHLS(
                    quality: quality,
                    fileName: fileName,
                    folder: folder
                )
                print("✅ HLSダウンロード完了: \(m3u8File.path)")

                // 合計ファイルサイズを計算（フォルダ内の全ファイル）
                let folderPath = m3u8File.deletingLastPathComponent()
                let totalSize = try calculateFolderSize(at: folderPath)

                // m3u8ファイルのパスを保存（相対パスとして）
                DownloadService.shared.saveDownloadedFile(
                    fileName: fileName.replacingOccurrences(of: ".m3u8", with: ""),
                    filePath: m3u8File.path,
                    fileSize: totalSize,
                    mimeType: "application/x-mpegURL",
                    folder: folder
                )

                await MainActor.run {
                    downloadedFileName = fileName.replacingOccurrences(of: ".m3u8", with: "")
                    downloadedFileSize = totalSize
                    showDownloadCompleted = true
                }
            } catch {
                print("❌ HLSダウンロードエラー: \(error)")
            }
        }
    }

    private func calculateFolderSize(at url: URL) throws -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                let fileAttributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = fileAttributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
        }

        return totalSize
    }
}

// WKWebViewをSwiftUIで使うためのラッパー
struct WebView: UIViewRepresentable {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject var tabManager: TabManager

    func makeUIView(context: Context) -> WKWebView {
        let webView = viewModel.webView
        webView.uiDelegate = context.coordinator

        // コンテキストメニューを完全に無効化
        webView.allowsLinkPreview = false

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 更新は不要
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, tabManager: tabManager)
    }

    class Coordinator: NSObject, WKUIDelegate {
        let viewModel: BrowserViewModel
        let tabManager: TabManager

        init(viewModel: BrowserViewModel, tabManager: TabManager) {
            self.viewModel = viewModel
            self.tabManager = tabManager
        }

        // リンク長押しで新規タブで開く & 動画ダウンロード
        func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
            // リンクの場合のみメニューを表示
            if let linkURL = elementInfo.linkURL {
                let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    var actions: [UIAction] = []

                    // 動画・画像・音声ファイルかチェック
                    let ext = linkURL.pathExtension.lowercased()
                    let isVideo = ["mp4", "mov", "m4v", "avi", "mkv", "webm", "flv"].contains(ext)
                    let isImage = ["jpg", "jpeg", "png", "gif", "webp", "bmp"].contains(ext)
                    let isAudio = ["mp3", "wav", "m4a", "flac", "aac"].contains(ext)

                    // 動画の場合は「動画をダウンロード」を追加
                    if isVideo {
                        let downloadVideo = UIAction(title: "動画をダウンロード", image: UIImage(systemName: "arrow.down.circle.fill")) { _ in
                            DispatchQueue.main.async {
                                let fileName = linkURL.lastPathComponent
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ShowDownloadDialog"),
                                    object: nil,
                                    userInfo: ["url": linkURL, "fileName": fileName]
                                )
                            }
                        }
                        actions.append(downloadVideo)
                    }

                    // 画像の場合は「画像をダウンロード」を追加
                    if isImage {
                        let downloadImage = UIAction(title: "画像をダウンロード", image: UIImage(systemName: "arrow.down.circle.fill")) { _ in
                            DispatchQueue.main.async {
                                let fileName = linkURL.lastPathComponent
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ShowDownloadDialog"),
                                    object: nil,
                                    userInfo: ["url": linkURL, "fileName": fileName]
                                )
                            }
                        }
                        actions.append(downloadImage)
                    }

                    // 音声の場合は「音声をダウンロード」を追加
                    if isAudio {
                        let downloadAudio = UIAction(title: "音声をダウンロード", image: UIImage(systemName: "arrow.down.circle.fill")) { _ in
                            DispatchQueue.main.async {
                                let fileName = linkURL.lastPathComponent
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ShowDownloadDialog"),
                                    object: nil,
                                    userInfo: ["url": linkURL, "fileName": fileName]
                                )
                            }
                        }
                        actions.append(downloadAudio)
                    }

                    // 新規タブで開く
                    let openInNewTab = UIAction(title: "新規タブで開く", image: UIImage(systemName: "plus.square.on.square")) { [weak self] _ in
                        DispatchQueue.main.async {
                            self?.tabManager.createNewTab(url: linkURL.absoluteString)
                            self?.viewModel.loadURL(linkURL.absoluteString)
                        }
                    }
                    actions.append(openInNewTab)

                    // URLをコピー
                    let copyURL = UIAction(title: "URLをコピー", image: UIImage(systemName: "doc.on.doc")) { _ in
                        UIPasteboard.general.string = linkURL.absoluteString
                    }
                    actions.append(copyURL)

                    // リンクをシェア
                    let shareLink = UIAction(title: "リンクをシェア", image: UIImage(systemName: "square.and.arrow.up")) { _ in
                        DispatchQueue.main.async {
                            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                  let window = windowScene.windows.first,
                                  let rootViewController = window.rootViewController else { return }

                            let activityVC = UIActivityViewController(activityItems: [linkURL], applicationActivities: nil)
                            if let popover = activityVC.popoverPresentationController {
                                popover.sourceView = window
                                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                            }
                            rootViewController.present(activityVC, animated: true)
                        }
                    }
                    actions.append(shareLink)

                    return UIMenu(title: "", children: actions)
                }
                completionHandler(config)
            } else {
                // リンク以外はメニュー無し
                completionHandler(nil)
            }
        }
    }
}
