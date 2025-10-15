//
//  BookmarkListView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI

struct BookmarkListView: View {
    @Environment(\.dismiss) var dismiss
    @State private var bookmarks: [Bookmark] = []
    @State private var folders: [String] = []
    @State private var selectedFolder: String?  // 選択されたフォルダ
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    @State private var showRenameFolder = false
    @State private var renamingFolder: String?
    var onSelectBookmark: (String) -> Void

    var body: some View {
        NavigationView {
            List {
                if selectedFolder == nil {
                    // フォルダなしのブックマーク（直接表示）
                    let homeBookmarks = BookmarkService.shared.fetchBookmarks().filter { $0.folder == nil || $0.folder?.isEmpty == true }
                    ForEach(homeBookmarks, id: \.id) { bookmark in
                        Button(action: {
                            onSelectBookmark(bookmark.url ?? "")
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bookmark.title ?? "無題")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(bookmark.url ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            BookmarkService.shared.deleteBookmark(homeBookmarks[index])
                        }
                    }

                    // フォルダ一覧表示
                    ForEach(folders, id: \.self) { folder in
                        Button(action: {
                            selectedFolder = folder
                            loadBookmarks(inFolder: folder)
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                Text(folder)
                                    .font(.headline)
                                Spacer()
                                let count = BookmarkService.shared.fetchBookmarks(inFolder: folder).count
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                renamingFolder = folder
                                newFolderName = folder
                                showRenameFolder = true
                            }) {
                                Label("名前変更", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: {
                                BookmarkService.shared.deleteFolder(folder)
                                loadFolders()
                            }) {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                } else {
                    // ブックマーク一覧表示
                    ForEach(bookmarks, id: \.id) { bookmark in
                        Button(action: {
                            onSelectBookmark(bookmark.url ?? "")
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bookmark.title ?? "無題")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(bookmark.url ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .onDelete { offsets in
                        deleteBookmarks(at: offsets)
                    }
                }
            }
            .navigationTitle(selectedFolder ?? "ブックマーク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedFolder != nil {
                        Button(action: {
                            selectedFolder = nil
                            loadFolders()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("フォルダ")
                            }
                        }
                    } else {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedFolder == nil {
                        Button(action: {
                            showCreateFolder = true
                        }) {
                            Image(systemName: "folder.badge.plus")
                        }
                    } else {
                        EditButton()
                    }
                }
            }
            .alert("新規フォルダ", isPresented: $showCreateFolder) {
                TextField("フォルダ名", text: $newFolderName)
                Button("作成") {
                    if !newFolderName.isEmpty {
                        // 新しいフォルダに空のブックマークを作成（フォルダを表示するため）
                        BookmarkService.shared.addBookmark(title: "", url: "", folder: newFolderName)
                        loadFolders()
                        newFolderName = ""
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
            .alert("フォルダ名変更", isPresented: $showRenameFolder) {
                TextField("フォルダ名", text: $newFolderName)
                Button("変更") {
                    if let oldName = renamingFolder, !newFolderName.isEmpty {
                        BookmarkService.shared.renameFolder(from: oldName, to: newFolderName)
                        loadFolders()
                        newFolderName = ""
                        renamingFolder = nil
                    }
                }
                Button("キャンセル", role: .cancel) {
                    renamingFolder = nil
                }
            }
            .onAppear {
                if selectedFolder == nil {
                    loadFolders()
                }
            }
        }
    }

    private func loadFolders() {
        folders = BookmarkService.shared.fetchFolders()
    }

    private func loadBookmarks(inFolder folder: String) {
        bookmarks = BookmarkService.shared.fetchBookmarks(inFolder: folder)
    }

    private func deleteBookmarks(at offsets: IndexSet) {
        for index in offsets {
            BookmarkService.shared.deleteBookmark(bookmarks[index])
        }
        if let folder = selectedFolder {
            loadBookmarks(inFolder: folder)
        }
    }
}

#Preview {
    BookmarkListView(onSelectBookmark: { _ in })
}
