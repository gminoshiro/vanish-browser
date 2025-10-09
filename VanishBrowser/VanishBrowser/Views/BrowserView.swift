//
//  BrowserView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI
import WebKit

struct BrowserView: View {
    @StateObject private var viewModel = BrowserViewModel()
    @State private var urlText: String = ""
    @State private var showBookmarks = false
    @State private var showDownloads = false
    @State private var isBookmarked = false

    var body: some View {
        VStack(spacing: 0) {
            // URLバー
            HStack {
                TextField("URLを入力またはキーワード検索", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onSubmit {
                        viewModel.loadURL(urlText)
                    }

                Button(action: {
                    viewModel.loadURL(urlText)
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                }
            }
            .padding()

            // WebView
            ZStack(alignment: .bottom) {
                WebView(viewModel: viewModel)

                // メディア検出時のダウンロードボタン
                if viewModel.detectedMediaURL != nil {
                    Button(action: {
                        if let url = viewModel.detectedMediaURL,
                           let fileName = viewModel.detectedMediaFileName {
                            viewModel.downloadFile(from: url, fileName: fileName)
                            viewModel.detectedMediaURL = nil
                            viewModel.detectedMediaFileName = nil
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 24))
                            Text("ダウンロード")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.9))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.bottom, 20)
                }
            }

            // ツールバー
            HStack(spacing: 30) {
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!viewModel.canGoBack)

                Button(action: { viewModel.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!viewModel.canGoForward)

                Button(action: { viewModel.reload() }) {
                    Image(systemName: "arrow.clockwise")
                }

                Spacer()

                Button(action: {
                    toggleBookmark()
                }) {
                    Image(systemName: isBookmarked ? "star.fill" : "star")
                        .foregroundColor(isBookmarked ? .yellow : .primary)
                }

                Button(action: {
                    showBookmarks = true
                }) {
                    Image(systemName: "book")
                }

                Button(action: {
                    showDownloads = true
                }) {
                    Image(systemName: "arrow.down.circle")
                }
            }
            .font(.title2)
            .padding()
        }
        .onChange(of: viewModel.currentURL) { _, newURL in
            urlText = newURL
            updateBookmarkStatus()
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarkListView(onSelectBookmark: { url in
                viewModel.loadURL(url)
            })
        }
        .sheet(isPresented: $showDownloads) {
            DownloadListView()
        }
    }

    private func toggleBookmark() {
        guard let url = viewModel.webView.url?.absoluteString,
              let title = viewModel.webView.title else { return }

        if isBookmarked {
            // 削除処理は一覧から行う
            showBookmarks = true
        } else {
            BookmarkService.shared.addBookmark(title: title, url: url)
            isBookmarked = true
        }
    }

    private func updateBookmarkStatus() {
        guard let url = viewModel.webView.url?.absoluteString else {
            isBookmarked = false
            return
        }
        isBookmarked = BookmarkService.shared.isBookmarked(url: url)
    }
}

// WKWebViewをSwiftUIで使うためのラッパー
struct WebView: UIViewRepresentable {
    @ObservedObject var viewModel: BrowserViewModel

    func makeUIView(context: Context) -> WKWebView {
        let webView = viewModel.webView
        webView.uiDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 更新は不要
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, WKUIDelegate {
        let viewModel: BrowserViewModel

        init(viewModel: BrowserViewModel) {
            self.viewModel = viewModel
        }

        // コンテキストメニューのカスタマイズ
        func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {

            // JavaScriptで画像URLを同期的に取得（遅延なし）
            let jsCode = """
            (function() {
                var elements = document.elementsFromPoint(\(elementInfo.location.x), \(elementInfo.location.y));
                for (var i = 0; i < elements.length; i++) {
                    if (elements[i].tagName === 'IMG') {
                        return { type: 'image', url: elements[i].src || elements[i].currentSrc };
                    }
                }
                return null;
            })();
            """

            var detectedImageURL: URL?

            // 同期的に画像URLを取得
            let semaphore = DispatchSemaphore(value: 0)
            webView.evaluateJavaScript(jsCode) { result, error in
                if let dict = result as? [String: String],
                   dict["type"] == "image",
                   let urlString = dict["url"],
                   let url = URL(string: urlString) {
                    detectedImageURL = url
                }
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 0.1)

            // リンクまたは画像がある場合のみメニューを表示
            let linkURL = elementInfo.linkURL
            let imageURL = detectedImageURL

            guard linkURL != nil || imageURL != nil else {
                completionHandler(nil)
                return
            }

            let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                var actions: [UIAction] = []

                // 画像のダウンロード（リンクなしの直接画像）
                if let imageURL = imageURL, linkURL == nil {
                    actions.append(UIAction(title: "画像をダウンロード", image: UIImage(systemName: "arrow.down.circle.fill")) { _ in
                        let fileName = imageURL.lastPathComponent.isEmpty ? "image.jpg" : imageURL.lastPathComponent
                        self.viewModel.downloadFile(from: imageURL, fileName: fileName)
                    })

                    actions.append(UIAction(title: "画像URLをコピー", image: UIImage(systemName: "doc.on.doc")) { _ in
                        UIPasteboard.general.string = imageURL.absoluteString
                    })
                }

                // リンクがある場合
                if let linkURL = linkURL {
                    // リンクを開く
                    actions.append(UIAction(title: "リンクを開く", image: UIImage(systemName: "link")) { _ in
                        webView.load(URLRequest(url: linkURL))
                    })

                    // ダウンロード可能なファイルの場合
                    if self.isDownloadableURL(linkURL) {
                        let fileType = self.getFileType(linkURL)
                        let title = fileType == "画像" ? "画像をダウンロード" : fileType == "動画" ? "動画をダウンロード" : "ダウンロード"

                        actions.append(UIAction(title: title, image: UIImage(systemName: "arrow.down.circle.fill")) { _ in
                            let fileName = linkURL.lastPathComponent.isEmpty ? "download" : linkURL.lastPathComponent
                            self.viewModel.downloadFile(from: linkURL, fileName: fileName)
                        })
                    }

                    // リンクをコピー
                    actions.append(UIAction(title: "リンクをコピー", image: UIImage(systemName: "doc.on.doc")) { _ in
                        UIPasteboard.general.string = linkURL.absoluteString
                    })
                }

                return UIMenu(title: "", children: actions)
            }

            completionHandler(config)
        }

        private func getFileType(_ url: URL) -> String {
            let ext = url.pathExtension.lowercased()
            if ["jpg", "jpeg", "png", "gif", "webp"].contains(ext) {
                return "画像"
            } else if ["mp4", "mov", "avi", "mkv", "webm"].contains(ext) {
                return "動画"
            } else if ["mp3", "wav", "m4a", "flac"].contains(ext) {
                return "音声"
            }
            return "ファイル"
        }

        private func isDownloadableURL(_ url: URL) -> Bool {
            let downloadableExtensions = ["mp4", "mov", "avi", "mkv", "webm", "mp3", "wav", "m4a", "flac", "pdf", "zip", "jpg", "jpeg", "png", "gif"]
            let ext = url.pathExtension.lowercased()
            return downloadableExtensions.contains(ext)
        }
    }
}

#Preview {
    BrowserView()
}
