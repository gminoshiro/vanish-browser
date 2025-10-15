//
//  BookmarkFolderSelectionView.swift
//  VanishBrowser
//
//  ブックマーク保存時のフォルダ選択画面
//

import SwiftUI

struct BookmarkFolderSelectionView: View {
    let bookmarkTitle: String
    let bookmarkURL: String
    @Binding var selectedFolder: String
    let onSave: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var folders: [String] = []
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("保存先フォルダを選択")) {
                    // ホーム選択肢
                    Button(action: {
                        selectedFolder = ""
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.blue)
                            Text("ホーム")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedFolder.isEmpty {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    // フォルダ一覧
                    ForEach(folders, id: \.self) { folder in
                        Button(action: {
                            selectedFolder = folder
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                Text(folder)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedFolder == folder {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }

                    Button(action: {
                        showNewFolderAlert = true
                    }) {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.blue)
                            Text("新規フォルダ")
                                .foregroundColor(.blue)
                        }
                    }
                }

                Section(header: Text("ブックマーク情報")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bookmarkTitle)
                            .font(.headline)
                        Text(bookmarkURL)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("ブックマークを保存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave()
                        dismiss()
                    }
                }
            }
            .alert("新規フォルダ", isPresented: $showNewFolderAlert) {
                TextField("フォルダ名", text: $newFolderName)
                Button("作成") {
                    if !newFolderName.isEmpty {
                        selectedFolder = newFolderName
                        loadFolders()
                        newFolderName = ""
                    }
                }
                Button("キャンセル", role: .cancel) {
                    newFolderName = ""
                }
            }
            .onAppear {
                loadFolders()
            }
        }
    }

    private func loadFolders() {
        folders = BookmarkService.shared.fetchFolders()
        // 新しいフォルダが追加された場合はリストに含める
        if !folders.contains(selectedFolder) && !selectedFolder.isEmpty {
            folders.append(selectedFolder)
        }
    }
}
