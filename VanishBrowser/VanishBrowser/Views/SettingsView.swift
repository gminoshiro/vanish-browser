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
    @AppStorage("searchEngine") private var searchEngine: String = SearchEngine.google.rawValue
    @AppStorage("authEnabled") private var authEnabled: Bool = false
    @AppStorage("useBiometric") private var useBiometric: Bool = true
    @AppStorage("authPassword") private var authPassword: String = ""
    @State private var showDeleteConfirmation = false
    @State private var storageUsage: (totalBytes: Int64, fileCount: Int) = (0, 0)
    @State private var availableStorage: Int64? = nil
    @State private var passwordInput: String = ""

    var selectedSearchEngine: SearchEngine {
        SearchEngine(rawValue: searchEngine) ?? .google
    }

    var body: some View {
        NavigationView {
            List {
                // デフォルトブラウザ設定
                Section(header: Text("デフォルトブラウザ"), footer: Text("Vanish Browserをデフォルトブラウザに設定すると、他のアプリでリンクをタップしたときにこのブラウザで開きます。")) {
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
                }

                // 認証設定
                Section(header: Text("認証"), footer: Text(authEnabled ? (useBiometric ? "生体認証が利用できない場合、パスワード認証にフォールバックします。" : "任意のパスワードを設定できます。") : "アプリ起動時の認証を有効にできます。")) {
                    Toggle("認証を使用", isOn: $authEnabled)

                    if authEnabled {
                        Toggle("生体認証を使用", isOn: $useBiometric)
                            .disabled(false)

                        if !useBiometric {
                            SecureField("パスワード", text: $passwordInput)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                                .autocapitalization(.none)
                                .onChange(of: passwordInput) { _, newValue in
                                    authPassword = newValue
                                }

                            if !authPassword.isEmpty {
                                Text("パスワードが設定されています")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Button("パスワードをクリア") {
                                    authPassword = ""
                                    passwordInput = ""
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
                // ストレージ情報
                Section(header: Text("ストレージ")) {
                    HStack {
                        Text("ダウンロード済みファイル")
                        Spacer()
                        Text("\(storageUsage.fileCount)件")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("使用容量")
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

                // 検索エンジン設定
                Section(header: Text("検索エンジン")) {
                    Picker("検索エンジン", selection: $searchEngine) {
                        ForEach(SearchEngine.allCases, id: \.rawValue) { engine in
                            Text(engine.rawValue).tag(engine.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 自動削除設定
                Section(header: Text("自動削除"), footer: Text("設定した時間が経過すると、選択したデータが自動的に削除されます。")) {
                    Picker("削除タイミング", selection: $autoDeleteService.autoDeleteMode) {
                        ForEach(AutoDeleteMode.allCases, id: \.rawValue) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 削除対象設定
                Section(header: Text("削除対象")) {
                    Toggle("閲覧履歴", isOn: $autoDeleteService.deleteBrowsingHistory)
                    Toggle("ダウンロードファイル", isOn: $autoDeleteService.deleteDownloads)
                    Toggle("ブックマーク", isOn: $autoDeleteService.deleteBookmarks)
                }

                // 手動削除
                Section(header: Text("手動削除")) {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("すべてのデータを削除")
                                .foregroundColor(.red)
                        }
                    }
                }

                // タイマー情報
                if autoDeleteService.autoDeleteMode != .disabled {
                    Section(header: Text("タイマー情報")) {
                        HStack {
                            Text("次回削除まで")
                            Spacer()
                            Text(autoDeleteService.getTimeUntilNextDelete())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("すべてのデータを削除", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    autoDeleteService.deleteAllData()
                    loadStorageInfo() // 削除後に再読み込み
                }
            } message: {
                Text("閲覧履歴、ダウンロードファイル、ブックマークがすべて削除されます。この操作は取り消せません。")
            }
            .onAppear {
                loadStorageInfo()
                passwordInput = authPassword // パスワード入力欄を初期化
            }
        }
    }

    private func loadStorageInfo() {
        storageUsage = DownloadService.shared.calculateStorageUsage()
        availableStorage = DownloadService.shared.getAvailableStorage()
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    SettingsView()
}
