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

    private var hasDeleteTarget: Bool {
        autoDeleteService.deleteBrowsingHistory ||
        autoDeleteService.deleteDownloads ||
        autoDeleteService.deleteBookmarks ||
        autoDeleteService.deleteTabs
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("削除タイミング").padding(.top, 8)) {
                    Picker("自動削除タイミング", selection: $autoDeleteService.autoDeleteMode) {
                        ForEach(AutoDeleteMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!hasDeleteTarget)
                }

                Section(header: Text("削除する内容").padding(.top, 8), footer: footerText) {
                    Toggle("閲覧履歴", isOn: $autoDeleteService.deleteBrowsingHistory)
                        .onChange(of: autoDeleteService.deleteBrowsingHistory) { _, _ in
                            checkDeleteTargets()
                        }
                    Toggle("ダウンロード", isOn: $autoDeleteService.deleteDownloads)
                        .onChange(of: autoDeleteService.deleteDownloads) { _, _ in
                            checkDeleteTargets()
                        }
                    Toggle("ブックマーク", isOn: $autoDeleteService.deleteBookmarks)
                        .onChange(of: autoDeleteService.deleteBookmarks) { _, _ in
                            checkDeleteTargets()
                        }
                    Toggle("タブ", isOn: $autoDeleteService.deleteTabs)
                        .onChange(of: autoDeleteService.deleteTabs) { _, _ in
                            checkDeleteTargets()
                        }
                }

                Section(header: Text("手動削除").padding(.top, 8)) {
                    Button(action: {
                        // 現在の設定を初期値として確認ダイアログに設定
                        confirmDeleteHistory = autoDeleteService.deleteBrowsingHistory
                        confirmDeleteDownloads = autoDeleteService.deleteDownloads
                        confirmDeleteBookmarks = autoDeleteService.deleteBookmarks
                        confirmDeleteTabs = autoDeleteService.deleteTabs
                        showDeleteConfirmation = true
                    }) {
                        Label("選択した内容を今すぐ削除", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                    .disabled(!autoDeleteService.deleteBrowsingHistory &&
                              !autoDeleteService.deleteDownloads &&
                              !autoDeleteService.deleteBookmarks &&
                              !autoDeleteService.deleteTabs)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("自動削除")
            .navigationBarTitleDisplayMode(.inline)
            .alert("削除の確認", isPresented: $showDeleteConfirmation) {
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

    private func checkDeleteTargets() {
        // 削除対象が全てOFFになったら、自動削除タイミングを無効に戻す
        if !hasDeleteTarget && autoDeleteService.autoDeleteMode != .disabled {
            autoDeleteService.autoDeleteMode = .disabled
        }
    }

    private var footerText: Text {
        // 削除対象が未選択の場合
        if !hasDeleteTarget {
            return Text("先に削除する内容を選択してください")
        }

        switch autoDeleteService.autoDeleteMode {
        case .disabled:
            return Text("自動削除は無効です")
        case .onAppClose:
            return Text("最後にアプリを閉じてから直後に自動削除されます。期間内に一度でも開けばカウントがリセットされます")
        case .after1Hour:
            return Text("最後にアプリを閉じてから1時間後に自動削除されます。期間内に一度でも開けばカウントがリセットされます")
        case .after24Hours:
            return Text("最後にアプリを閉じてから24時間後に自動削除されます。期間内に一度でも開けばカウントがリセットされます")
        case .after3Days:
            return Text("最後にアプリを閉じてから3日後に自動削除されます。期間内に一度でも開けばカウントがリセットされます")
        case .after7Days:
            return Text("最後にアプリを閉じてから7日後に自動削除されます。期間内に一度でも開けばカウントがリセットされます")
        case .after30Days:
            return Text("最後にアプリを閉じてから30日後に自動削除されます。期間内に一度でも開けばカウントがリセットされます")
        case .after90Days:
            return Text("最後にアプリを閉じてから90日後に自動削除されます。期間内に一度でも開けばカウントがリセットされます")
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
            items.append("閲覧履歴")
        }
        if confirmDeleteDownloads {
            items.append("ダウンロード")
        }
        if confirmDeleteBookmarks {
            items.append("ブックマーク")
        }
        if confirmDeleteTabs {
            items.append("タブ")
        }

        if items.isEmpty {
            return "削除対象が選択されていません"
        }

        return items.joined(separator: "、") + "を削除します。この操作は取り消せません。"
    }
}

#Preview {
    AutoDeleteSettingsView()
}
