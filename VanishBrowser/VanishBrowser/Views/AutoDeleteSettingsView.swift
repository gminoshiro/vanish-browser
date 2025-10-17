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

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("自動削除タイミング")) {
                    Picker("削除タイミング", selection: $autoDeleteService.autoDeleteMode) {
                        ForEach(AutoDeleteMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)

                    if let interval = autoDeleteService.autoDeleteMode.timeInterval {
                        let remaining = getRemainingTime(interval: interval)
                        Text("次回削除まで: \(remaining)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("削除対象")) {
                    Toggle("閲覧履歴", isOn: $autoDeleteService.deleteBrowsingHistory)
                    Toggle("ダウンロード", isOn: $autoDeleteService.deleteDownloads)
                    Toggle("ブックマーク", isOn: $autoDeleteService.deleteBookmarks)

                    if !autoDeleteService.deleteBrowsingHistory &&
                       !autoDeleteService.deleteDownloads &&
                       !autoDeleteService.deleteBookmarks {
                        Text("⚠️ 削除対象が選択されていません")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Section(header: Text("即座に削除")) {
                    Button(action: {
                        print("🔴 今すぐ削除ボタンが押されました")
                        // 現在の設定を初期値として確認ダイアログに設定
                        confirmDeleteHistory = autoDeleteService.deleteBrowsingHistory
                        confirmDeleteDownloads = autoDeleteService.deleteDownloads
                        confirmDeleteBookmarks = autoDeleteService.deleteBookmarks
                        print("🔴 設定: 履歴=\(confirmDeleteHistory), DL=\(confirmDeleteDownloads), BM=\(confirmDeleteBookmarks)")
                        showDeleteConfirmation = true
                        print("🔴 showDeleteConfirmation = \(showDeleteConfirmation)")
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("今すぐ削除")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("自動削除設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .alert("削除確認", isPresented: $showDeleteConfirmation) {
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

    private func executeDelete() {
        autoDeleteService.performManualDelete(
            history: confirmDeleteHistory,
            downloads: confirmDeleteDownloads,
            bookmarks: confirmDeleteBookmarks
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

        if items.isEmpty {
            return "削除対象が選択されていません"
        }

        return "以下の項目を削除します:\n\n" + items.joined(separator: "\n")
    }

    private func getRemainingTime(interval: TimeInterval) -> String {
        guard let lastActiveDate = UserDefaults.standard.object(forKey: "lastActiveDate") as? Date else {
            return "未設定"
        }

        let elapsed = Date().timeIntervalSince(lastActiveDate)
        let remaining = interval - elapsed

        if remaining <= 0 {
            return "次回起動時に削除"
        }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)日"
        } else if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

#Preview {
    AutoDeleteSettingsView()
}
