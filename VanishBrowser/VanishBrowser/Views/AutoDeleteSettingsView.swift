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
                Section(header: Text(NSLocalizedString("settings.deleteTiming", comment: "")).padding(.top, 8), footer: footerText) {
                    Picker(NSLocalizedString("settings.deleteTiming", comment: ""), selection: $autoDeleteService.autoDeleteMode) {
                        ForEach(AutoDeleteMode.allCases, id: \.self) { mode in
                            Text(mode.displayShortText).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!hasDeleteTarget)
                }

                Section(header: Text(NSLocalizedString("settings.deleteTargets", comment: "")).padding(.top, 8)) {
                    Toggle(NSLocalizedString("browser.history", comment: ""), isOn: $autoDeleteService.deleteBrowsingHistory)
                        .onChange(of: autoDeleteService.deleteBrowsingHistory) { _, _ in
                            checkDeleteTargets()
                        }
                    Toggle(NSLocalizedString("downloads.title", comment: ""), isOn: $autoDeleteService.deleteDownloads)
                        .onChange(of: autoDeleteService.deleteDownloads) { _, _ in
                            checkDeleteTargets()
                        }
                    Toggle(NSLocalizedString("bookmarks.title", comment: ""), isOn: $autoDeleteService.deleteBookmarks)
                        .onChange(of: autoDeleteService.deleteBookmarks) { _, _ in
                            checkDeleteTargets()
                        }
                    Toggle(NSLocalizedString("tabs.title", comment: ""), isOn: $autoDeleteService.deleteTabs)
                        .onChange(of: autoDeleteService.deleteTabs) { _, _ in
                            checkDeleteTargets()
                        }
                }

                Section(header: Text(NSLocalizedString("settings.manualDelete", comment: "")).padding(.top, 8)) {
                    Button(action: {
                        // 現在の設定を初期値として確認ダイアログに設定
                        confirmDeleteHistory = autoDeleteService.deleteBrowsingHistory
                        confirmDeleteDownloads = autoDeleteService.deleteDownloads
                        confirmDeleteBookmarks = autoDeleteService.deleteBookmarks
                        confirmDeleteTabs = autoDeleteService.deleteTabs
                        showDeleteConfirmation = true
                    }) {
                        Label(NSLocalizedString("settings.deleteNow", comment: ""), systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                    .disabled(!autoDeleteService.deleteBrowsingHistory &&
                              !autoDeleteService.deleteDownloads &&
                              !autoDeleteService.deleteBookmarks &&
                              !autoDeleteService.deleteTabs)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("settings.autoDelete", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("button.close", comment: "")) {
                        dismiss()
                    }
                }
            }
            .alert(NSLocalizedString("alert.delete.title", comment: ""), isPresented: $showDeleteConfirmation) {
                Button(NSLocalizedString("button.cancel", comment: ""), role: .cancel) {}
                Button(NSLocalizedString("button.delete", comment: ""), role: .destructive) {
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
            return Text(NSLocalizedString("alert.selectTargetsFirst", comment: ""))
        }

        switch autoDeleteService.autoDeleteMode {
        case .disabled:
            return Text(NSLocalizedString("settings.autoDelete.disabled", comment: ""))
        case .onAppClose:
            return Text(NSLocalizedString("settings.autoDelete.onAppClose.description", comment: ""))
        case .after1Hour:
            return Text(NSLocalizedString("settings.autoDelete.after1Hour.description", comment: ""))
        case .after24Hours:
            return Text(NSLocalizedString("settings.autoDelete.after24Hours.description", comment: ""))
        case .after3Days:
            return Text(NSLocalizedString("settings.autoDelete.after3Days.description", comment: ""))
        case .after7Days:
            return Text(NSLocalizedString("settings.autoDelete.after7Days.description", comment: ""))
        case .after30Days:
            return Text(NSLocalizedString("settings.autoDelete.after30Days.description", comment: ""))
        case .after90Days:
            return Text(NSLocalizedString("settings.autoDelete.after90Days.description", comment: ""))
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
            items.append(NSLocalizedString("browser.history", comment: ""))
        }
        if confirmDeleteDownloads {
            items.append(NSLocalizedString("downloads.title", comment: ""))
        }
        if confirmDeleteBookmarks {
            items.append(NSLocalizedString("bookmarks.title", comment: ""))
        }
        if confirmDeleteTabs {
            items.append(NSLocalizedString("tabs.title", comment: ""))
        }

        if items.isEmpty {
            return NSLocalizedString("alert.delete.noTargets", comment: "")
        }

        let joined = items.joined(separator: ", ")
        return String(format: "%@ %@", joined, NSLocalizedString("alert.delete.confirmation", comment: ""))
    }
}

#Preview {
    AutoDeleteSettingsView()
}
