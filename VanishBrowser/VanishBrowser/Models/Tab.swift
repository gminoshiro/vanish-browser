//
//  Tab.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/10.
//

import Foundation
import UIKit
import WebKit
import Combine

class Tab: Identifiable, ObservableObject, Equatable {
    let id: UUID
    @Published var title: String
    @Published var url: String
    @Published var snapshot: UIImage?
    let isPrivate: Bool
    let webView: WKWebView
    let createdAt: Date  // 自動削除用

    init(id: UUID = UUID(), title: String = "新規タブ", url: String = "", snapshot: UIImage? = nil, isPrivate: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.url = url
        self.snapshot = snapshot
        self.isPrivate = isPrivate
        self.createdAt = createdAt

        // タブごとにWKWebViewを作成
        let configuration = WebViewConfigurator.createConfiguration(isPrivate: isPrivate)
        self.webView = WKWebView(frame: .zero, configuration: configuration)
    }

    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.url == rhs.url &&
               lhs.isPrivate == rhs.isPrivate
        // snapshotとwebViewは比較から除外
    }
}
