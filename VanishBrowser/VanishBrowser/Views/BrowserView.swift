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

        // コンテキストメニューを完全に無効化（JavaScriptで独自実装）
        func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
            // nilを返してデフォルトメニューを無効化
            completionHandler(nil)
        }
    }
}
