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
    @State private var showDeleteConfirmation = false

    var selectedSearchEngine: SearchEngine {
        SearchEngine(rawValue: searchEngine) ?? .google
    }

    var body: some View {
        NavigationView {
            List {
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

                    if autoDeleteService.autoDeleteMode != .disabled {
                        Toggle("アプリ終了時に削除", isOn: $autoDeleteService.deleteOnAppClose)
                    }
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
                }
            } message: {
                Text("閲覧履歴、ダウンロードファイル、ブックマークがすべて削除されます。この操作は取り消せません。")
            }
        }
    }
}

#Preview {
    SettingsView()
}
