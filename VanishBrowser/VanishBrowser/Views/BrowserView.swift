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
                    VStack {
                        Spacer()
                        Button(action: {
                            if let url = viewModel.detectedMediaURL,
                               let fileName = viewModel.detectedMediaFileName {
                                viewModel.downloadFile(from: url, fileName: fileName)
                                viewModel.detectedMediaURL = nil
                                viewModel.detectedMediaFileName = nil
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("動画をダウンロード")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(25)
                            .shadow(radius: 5)
                        }
                        .padding(.bottom, 80)
                    }
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
        return viewModel.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 更新は不要
    }
}

#Preview {
    BrowserView()
}
