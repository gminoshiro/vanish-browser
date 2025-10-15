//
//  CookieManagerView.swift
//  VanishBrowser
//
//  Created by Claude on 2025/10/12.
//

import SwiftUI
import WebKit

struct CookieManagerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var cookies: [HTTPCookie] = []
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("読み込み中...")
                } else if cookies.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "trash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Cookieはありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        Section(header: Text("保存されているCookie (\(cookies.count)件)")) {
                            ForEach(cookies, id: \.self) { cookie in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cookie.name)
                                        .font(.headline)
                                    Text(cookie.domain)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let expiresDate = cookie.expiresDate {
                                        Text("期限: \(expiresDate.formatted())")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        deleteCookie(cookie)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        Section {
                            Button(role: .destructive, action: {
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("すべてのCookieを削除")
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cookie管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadCookies) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("すべてのCookieを削除", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    deleteAllCookies()
                }
            } message: {
                Text("すべてのCookieを削除してもよろしいですか？")
            }
            .onAppear {
                loadCookies()
            }
        }
    }

    private func loadCookies() {
        isLoading = true
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        cookieStore.getAllCookies { loadedCookies in
            DispatchQueue.main.async {
                self.cookies = loadedCookies.sorted { $0.domain < $1.domain }
                self.isLoading = false
                print("✅ Cookie読み込み: \(loadedCookies.count)件")
            }
        }
    }

    private func deleteCookie(_ cookie: HTTPCookie) {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        cookieStore.delete(cookie) {
            DispatchQueue.main.async {
                self.cookies.removeAll { $0 == cookie }
                print("✅ Cookie削除: \(cookie.name)")
            }
        }
    }

    private func deleteAllCookies() {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        cookies.forEach { cookie in
            cookieStore.delete(cookie)
        }
        DispatchQueue.main.async {
            self.cookies.removeAll()
            print("✅ すべてのCookie削除完了")
        }
    }
}
