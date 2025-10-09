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
            WebView(viewModel: viewModel)

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
                    // ダウンロード一覧（後で実装）
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
        return viewModel.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 更新は不要
    }
}

#Preview {
    BrowserView()
}
