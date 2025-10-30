//
//  AutoDeleteSettingsView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/16.
//

import SwiftUI

struct AutoDeleteSettingsView: View {
    @ObservedObject var autoDeleteService = AutoDeleteService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    @State private var confirmDeleteHistory = false
    @State private var confirmDeleteDownloads = false
    @State private var confirmDeleteBookmarks = false
    @State private var confirmDeleteTabs = false

    var body: some View {
        NavigationView {
            List {
                Section(footer: footerText) {
                    Picker("自動削除タイミング", selection: $autoDeleteService.autoDeleteMode) {
                        ForEach(AutoDeleteMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("削除対象"), footer: Text("選択した項目が自動的に削除されます")) {
                    Toggle("閲覧履歴", isOn: $autoDeleteService.deleteBrowsingHistory)
                    Toggle("ダウンロード", isOn: $autoDeleteService.deleteDownloads)
                    Toggle("ブックマーク", isOn: $autoDeleteService.deleteBookmarks)
                    Toggle("タブ", isOn: $autoDeleteService.deleteTabs)
                }

                Section {
                    Button(action: {
                        // 現在の設定を初期値として確認ダイアログに設定
                        confirmDeleteHistory = autoDeleteService.deleteBrowsingHistory
                        confirmDeleteDownloads = autoDeleteService.deleteDownloads
                        confirmDeleteBookmarks = autoDeleteService.deleteBookmarks
                        confirmDeleteTabs = autoDeleteService.deleteTabs
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("今すぐ削除")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(!autoDeleteService.deleteBrowsingHistory &&
                              !autoDeleteService.deleteDownloads &&
                              !autoDeleteService.deleteBookmarks &&
                              !autoDeleteService.deleteTabs)
                }
            }
            .navigationTitle("自動削除")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .alert("選択したデータを削除しますか？", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    executeDelete()
                    dismiss()
                }
            } message: {
                Text(getDeleteConfirmationMessage())
            }
        }
    }

    private var footerText: Text {
        switch autoDeleteService.autoDeleteMode {
        case .disabled:
            return Text("自動削除は無効です")
        case .onAppClose:
            return Text("アプリが使用されなくなった直後にデータを削除します（閉じる含む）")
        case .after1Hour:
            return Text("アプリが使用されなくなってから1時間後にデータを削除します（閉じる含む）")
        case .after24Hours:
            return Text("アプリが使用されなくなってから24時間後にデータを削除します（閉じる含む）")
        case .after3Days:
            return Text("アプリが使用されなくなってから3日後にデータを削除します（閉じる含む）")
        case .after7Days:
            return Text("アプリが使用されなくなってから7日後にデータを削除します（閉じる含む）")
        case .after30Days:
            return Text("アプリが使用されなくなってから30日後にデータを削除します（閉じる含む）")
        case .after90Days:
            return Text("アプリが使用されなくなってから90日後にデータを削除します（閉じる含む）")
        }
    }

    private func executeDelete() {
        autoDeleteService.performManualDelete(
            history: confirmDeleteHistory,
            downloads: confirmDeleteDownloads,
            bookmarks: confirmDeleteBookmarks,
            tabs: confirmDeleteTabs
        )
    }

    private func getDeleteConfirmationMessage() -> String {
        var items: [String] = []

        if confirmDeleteHistory {
            items.append("• 閲覧履歴")
        }
        if confirmDeleteDownloads {
            items.append("• ダウンロード")
        }
        if confirmDeleteBookmarks {
            items.append("• ブックマーク")
        }
        if confirmDeleteTabs {
            items.append("• タブ")
        }

        if items.isEmpty {
            return "削除対象が選択されていません"
        }

        return "以下の項目を削除します:\n\n" + items.joined(separator: "\n")
    }
}

#Preview {
    AutoDeleteSettingsView()
}
