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
    var onSelectBookmark: (String) -> Void

    var body: some View {
        NavigationView {
            List {
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
                .onDelete(perform: deleteBookmarks)
            }
            .navigationTitle("ブックマーク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .onAppear {
                loadBookmarks()
            }
        }
    }

    private func loadBookmarks() {
        bookmarks = BookmarkService.shared.fetchBookmarks()
    }

    private func deleteBookmarks(at offsets: IndexSet) {
        for index in offsets {
            BookmarkService.shared.deleteBookmark(bookmarks[index])
        }
        loadBookmarks()
    }
}

#Preview {
    BookmarkListView(onSelectBookmark: { _ in })
}
