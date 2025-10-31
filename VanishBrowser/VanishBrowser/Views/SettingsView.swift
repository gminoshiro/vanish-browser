//
//  SettingsView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var autoDeleteService = AutoDeleteService.shared
    @AppStorage("searchEngine") private var searchEngine: String = SearchEngine.duckDuckGo.rawValue
    @AppStorage("authEnabled") private var authEnabled: Bool = false
    @AppStorage("useBiometric") private var useBiometric: Bool = true
    @AppStorage("authPassword") private var authPassword: String = ""
    @State private var showDeleteConfirmation = false
    @State private var storageUsage: (totalBytes: Int64, fileCount: Int) = (0, 0)
    @State private var availableStorage: Int64? = nil
    @State private var showPasscodeSettings = false
    @State private var showCookieManager = false

    var selectedSearchEngine: SearchEngine {
        SearchEngine(rawValue: searchEngine) ?? .google
    }

    var body: some View {
        NavigationView {
            List {
                // 一般設定
                Section(header: Text("一般").padding(.top, 8)) {
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("デフォルトブラウザに設定")
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundColor(.blue)
                        }
                    }

                    Picker("検索エンジン", selection: $searchEngine) {
                        ForEach(SearchEngine.allCases, id: \.rawValue) { engine in
                            Text(engine.rawValue).tag(engine.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // セキュリティ設定
                Section(header: Text("セキュリティ").padding(.top, 8), footer: Text(authEnabled ? (useBiometric ? "生体認証が使えない時はパスコードで開けます" : "4桁の数字パスコードで認証します。") : "アプリ起動時の認証を有効にできます。")) {
                    Toggle("認証を使用", isOn: $authEnabled)
                        .onChange(of: authEnabled) { _, newValue in
                            if newValue && authPassword.isEmpty {
                                // 認証ONにした時にパスコード未設定なら設定画面を表示
                                showPasscodeSettings = true
                            }
                        }

                    if authEnabled {
                        // パスコード設定（生体認証使用時も必須）
                        if !authPassword.isEmpty {
                            HStack {
                                Text("パスコードが設定されています")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }

                            Button("パスコードを変更") {
                                showPasscodeSettings = true
                            }

                            Button("パスコードをクリア") {
                                authPassword = ""
                                // パスコードクリア時は生体認証もOFFにする
                                useBiometric = false
                            }
                            .foregroundColor(.red)
                        } else {
                            Button("パスコードを設定（必須）") {
                                showPasscodeSettings = true
                            }
                            .foregroundColor(.orange)
                        }

                        // 生体認証トグル（パスコード設定済みの場合のみ有効）
                        Toggle("生体認証を使用", isOn: $useBiometric)
                            .disabled(authPassword.isEmpty)
                            .onChange(of: useBiometric) { _, newValue in
                                if newValue && authPassword.isEmpty {
                                    // パスコード未設定なら警告
                                    useBiometric = false
                                }
                            }
                    }
                }
                // ストレージ情報
                Section(header: Text("ストレージ").padding(.top, 8)) {
                    NavigationLink(destination: DownloadListView()) {
                        HStack {
                            Text("ダウンロード")
                            Spacer()
                            Text("\(storageUsage.fileCount)件")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("アプリ使用容量")
                        Spacer()
                        Text(formatBytes(storageUsage.totalBytes))
                            .foregroundColor(.secondary)
                    }

                    if let available = availableStorage {
                        HStack {
                            Text("デバイス空き容量")
                            Spacer()
                            Text(formatBytes(available))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // データ管理
                Section(header: Text("データ管理").padding(.top, 8)) {
                    NavigationLink(destination: AutoDeleteSettingsView()) {
                        HStack {
                            Text("自動削除")
                            Spacer()
                            Text(autoDeleteService.autoDeleteMode.displayShortText)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("すべてのデータを今すぐ削除")
                                .foregroundColor(.red)
                        }
                    }
                }

                // その他
                Section(header: Text("その他").padding(.top, 8)) {
                    Button(action: {
                        // App IDは後でApp Store Connectで確認して設定
                        // 開発中は動作しない（App Store公開後に有効）
                        let appID = "YOUR_APP_ID"
                        ReviewManager.shared.openReviewPage(appID: appID)
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("App Storeでレビューを書く")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

                    Button(action: {
                        showCookieManager = true
                    }) {
                        HStack {
                            Label("Cookie管理", systemImage: "folder.badge.gearshape")
                            Spacer()
                        }
                        .foregroundColor(.primary)
                    }

                    NavigationLink(destination: LicenseView()) {
                        Label("ライセンス", systemImage: "doc.text")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("すべて削除", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    autoDeleteService.deleteAllData()
                    loadStorageInfo() // 削除後に再読み込み
                }
            } message: {
                Text("閲覧履歴、ダウンロード、ブックマーク、タブをすべて削除します。この操作は取り消せません。")
            }
            .onAppear {
                loadStorageInfo()
            }
            .sheet(isPresented: $showPasscodeSettings) {
                PasscodeSettingsView()
            }
            .sheet(isPresented: $showCookieManager) {
                CookieManagerView()
            }
        }
    }

    private func loadStorageInfo() {
        storageUsage = DownloadService.shared.calculateStorageUsage()
        availableStorage = DownloadService.shared.getAvailableStorage()
    }

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes == 0 {
            return "0 KB"
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    SettingsView()
}
