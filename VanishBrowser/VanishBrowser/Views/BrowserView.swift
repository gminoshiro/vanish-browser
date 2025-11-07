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
    @State private var showAutoDeleteSettings = false

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
            if viewModel.showToolbars {
                HStack {
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
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

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
                // ホーム画面（新規タブ時）
                if viewModel.currentURL.isEmpty || viewModel.currentURL == "about:blank" {
                    HomeView(
                        onSearch: { query in
                            viewModel.loadURL(query)
                            urlText = query
                        },
                        onBookmarkTap: { url in
                            viewModel.loadURL(url)
                            urlText = url
                        }
                    )
                    .transition(.opacity)
                    .zIndex(2)
                }

                // 通常のWebViewまたはリーダーモード
                if viewModel.isReaderMode {
                    ReaderModeView(htmlContent: viewModel.readerContent)
                        .transition(.opacity)
                } else {
                    WebView(viewModel: viewModel, tabManager: tabManager)
                        .opacity(viewModel.currentURL.isEmpty || viewModel.currentURL == "about:blank" ? 0 : 1)
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
            if viewModel.showToolbars {
                HStack(spacing: 8) {
                    // 戻る/進む
                    Button(action: { viewModel.goBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(viewModel.canGoBack ? .primary : .secondary.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(!viewModel.canGoBack)

                    Button(action: { viewModel.goForward() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(viewModel.canGoForward ? .primary : .secondary.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(!viewModel.canGoForward)

                    Spacer()

                    // ダウンロード
                    Button(action: {
                        showDownloads = true
                    }) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())

                    // その他メニュー
                    Menu {
                    // 動画ダウンロード（動画検出時のみ）
                    if viewModel.hasVideo {
                        Button(action: {
                            if let videoURL = viewModel.currentVideoURL,
                               let fileName = viewModel.detectedMediaFileName {
                                pendingDownloadURL = videoURL
                                pendingDownloadFileName = fileName
                                showDownloadDialog = true
                            }
                        }) {
                            Label("動画をダウンロード", systemImage: "arrow.down.circle.fill")
                        }
                        Divider()
                    }

                    Button(action: {
                        pendingBookmarkTitle = viewModel.webView.title ?? ""
                        pendingBookmarkURL = viewModel.currentURL
                        showBookmarkFolderSelection = true
                    }) {
                        Label("ブックマークに追加", systemImage: "book")
                    }

                    Button(action: {
                        showBookmarks = true
                    }) {
                        Label("ブックマーク一覧", systemImage: "list.bullet")
                    }

                    Divider()

                    Button(action: {
                        showBrowsingHistory = true
                    }) {
                        Label("閲覧履歴", systemImage: "clock.arrow.circlepath")
                    }

                    Button(action: {
                        if let url = URL(string: viewModel.currentURL) {
                            shareItems = [url]
                            showShareSheet = true
                        }
                    }) {
                        Label("共有", systemImage: "square.and.arrow.up")
                    }

                    Button(action: {
                        showPageSearch.toggle()
                    }) {
                        Label("ページ内検索", systemImage: "magnifyingglass")
                    }

                    Divider()

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

                    Button(action: {
                        viewModel.toggleDesktopMode()
                    }) {
                        Label(
                            viewModel.isDesktopMode ? "モバイルサイト" : "デスクトップサイト",
                            systemImage: viewModel.isDesktopMode ? "iphone" : "desktopcomputer"
                        )
                    }

                    Divider()

                    Button(action: {
                        showAutoDeleteSettings = true
                    }) {
                        Label("自動削除", systemImage: "trash")
                    }

                    Button(action: {
                        showSettings = true
                    }) {
                        Label("設定", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                // タブボタン（右端）
                Button(action: {
                    // スナップショットを先に取得してから開く
                    if let tabId = tabManager.currentTabId {
                        captureSnapshot(for: tabId) {
                            showTabManager = true
                        }
                    } else {
                        showTabManager = true
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "square.on.square")
                            .font(.system(size: 18, weight: .medium))
                        Text("\(tabManager.activeTabs.count)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 8)
                .background(Color(UIColor.systemBackground))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .ignoresSafeArea(.keyboard)
            }
        }
        .onChange(of: viewModel.currentURL) { _, newURL in
            urlText = newURL

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
                    // 新規タブの場合はホーム画面を表示（URLを空のまま）
                    viewModel.currentURL = ""
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
        .sheet(isPresented: $showAutoDeleteSettings) {
            AutoDeleteSettingsView()
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
            // 初期表示時はバーを表示
            viewModel.showToolbars = true

            // viewModelにtabManagerをセット（履歴保存時のisPrivate判定用）
            viewModel.tabManager = tabManager

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
                    let isPrivate = userInfo["isPrivate"] as? Bool ?? false
                    // createNewTabが自動的にcurrentTabIdを設定するため、
                    // onChangeハンドラで新しいタブのURLが自動ロードされる
                    tabManager.createNewTab(url: url, isPrivate: isPrivate)
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

            // HLSダウンロード開始通知を受信（CustomVideoPlayerViewから）
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("StartHLSDownload"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let quality = userInfo["quality"] as? HLSQuality,
                   let format = userInfo["format"] as? DownloadFormat,
                   let fileName = userInfo["fileName"] as? String,
                   let folder = userInfo["folder"] as? String {
                    handleHLSDownload(quality: quality, format: format, fileName: fileName, folder: folder)
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

            // 外部URLを開く通知を受信（デフォルトブラウザ機能）
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("OpenExternalURL"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let urlString = userInfo["url"] as? String {
                    print("🌐 外部URLを開く: \(urlString)")
                    viewModel.loadURL(urlString)
                }
            }
        }
    }


    private func captureSnapshot(for tabId: UUID, completion: (() -> Void)? = nil) {
        // ホーム画面の場合は専用のスナップショットを生成
        if viewModel.currentURL.isEmpty || viewModel.currentURL == "about:blank" {
            let homeSnapshot = createHomeScreenSnapshot()
            DispatchQueue.main.async {
                self.tabManager.updateTab(tabId, snapshot: homeSnapshot)
                print("✅ ホーム画面スナップショット保存成功: \(tabId)")
                completion?()
            }
            return
        }

        let config = WKSnapshotConfiguration()
        config.snapshotWidth = 300 as NSNumber  // サムネイルサイズ

        viewModel.webView.takeSnapshot(with: config) { image, error in
            if let error = error {
                print("❌ スナップショット取得エラー: \(error)")
                completion?()
                return
            }

            if let image = image {
                // 画像を圧縮してメモリを節約
                if let compressedData = image.jpegData(compressionQuality: 0.5),
                   let compressedImage = UIImage(data: compressedData) {
                    DispatchQueue.main.async {
                        self.tabManager.updateTab(tabId, snapshot: compressedImage)
                        print("✅ スナップショット保存成功: \(tabId)")
                        completion?()
                    }
                }
            } else {
                completion?()
            }
        }
    }

    // ホーム画面のスナップショットを生成
    private func createHomeScreenSnapshot() -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // ダークグレー背景
            UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // "Vanish" テキスト - 白のみ
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let text = "Vanish"
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: 60,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)

            // 検索バー風の図形
            let searchBarRect = CGRect(x: 30, y: 120, width: size.width - 60, height: 44)
            let path = UIBezierPath(roundedRect: searchBarRect, cornerRadius: 12)
            UIColor.white.withAlphaComponent(0.1).setFill()
            path.fill()
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

    private func handleHLSDownload(quality: HLSQuality, format: DownloadFormat, fileName: String, folder: String) {
        // DownloadManagerを使用してHLSダウンロードを開始
        DownloadManager.shared.startHLSDownload(
            quality: quality,
            fileName: fileName,
            folder: folder
        )

        // ダウンロード完了の通知はDownloadManager内で処理されるため、
        // ここでは完了通知を表示しない
        print("✅ HLSダウンロードをDownloadManagerに登録: \(fileName)")
    }

    // 以前のhandleHLSDownload実装（参考用にコメントアウト）
    /*
    private func handleHLSDownloadOld(quality: HLSQuality, format: DownloadFormat, fileName: String, folder: String) {
        Task {
            do {
                if format == .mp4 {
                    // MP4形式でダウンロード（TSセグメント結合方式）
                    let mp4File = try await hlsDownloader.downloadHLS(
                        quality: quality,
                        fileName: fileName,
                        folder: folder
                    )
                    print("✅ HLS→MP4変換完了: \(mp4File.path)")

                    // ファイルサイズを取得
                    let fileSize = (try? FileManager.default.attributesOfItem(atPath: mp4File.path)[.size] as? Int64) ?? 0

                    // DownloadServiceに登録
                    DownloadService.shared.saveDownloadedFile(
                        fileName: mp4File.lastPathComponent,
                        filePath: mp4File.path,
                        fileSize: fileSize,
                        mimeType: "video/mp4",
                        folder: folder
                    )

                    await MainActor.run {
                        downloadedFileName = mp4File.lastPathComponent
                        downloadedFileSize = fileSize
                        showDownloadCompleted = true
                    }
                } else {
                    // m3u8形式でダウンロード
                    let m3u8File = try await hlsDownloader.downloadHLS(
                        quality: quality,
                        fileName: fileName,
                        folder: folder
                    )
                    print("✅ HLSダウンロード完了: \(m3u8File.path)")

                    // (コメントアウト)
                }
            } catch {
                print("❌ HLSダウンロードエラー: \(error)")
            }
        }
    }
    */

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
        webView.scrollView.delegate = context.coordinator

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

    class Coordinator: NSObject, WKUIDelegate, UIScrollViewDelegate {
        let viewModel: BrowserViewModel
        let tabManager: TabManager

        init(viewModel: BrowserViewModel, tabManager: TabManager) {
            self.viewModel = viewModel
            self.tabManager = tabManager
        }

        // スクロール検出
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            viewModel.handleScroll(offset: scrollView.contentOffset.y)
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
                    let openInNewTab = UIAction(title: NSLocalizedString("browser.tab.new", comment: ""), image: UIImage(systemName: "plus.square.on.square")) { [weak self] _ in
                        DispatchQueue.main.async {
                            // createNewTabが自動的にcurrentTabIdを設定するため、
                            // onChangeハンドラで新しいタブのURLが自動ロードされる
                            self?.tabManager.createNewTab(url: linkURL.absoluteString)
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

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
