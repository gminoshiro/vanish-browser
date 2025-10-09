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
                    // ブックマーク追加（後で実装）
                }) {
                    Image(systemName: "star")
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
