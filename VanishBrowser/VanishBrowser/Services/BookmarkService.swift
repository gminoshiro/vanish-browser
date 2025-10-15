//
//  BookmarkService.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import Foundation
import CoreData

class BookmarkService {
    static let shared = BookmarkService()

    private let viewContext = PersistenceController.shared.container.viewContext

    private init() {}

    // ブックマーク追加
    func addBookmark(title: String, url: String, folder: String) {
        let bookmark = Bookmark(context: viewContext)
        bookmark.id = UUID()
        bookmark.title = title
        bookmark.url = url
        bookmark.folder = folder.isEmpty ? nil : folder
        bookmark.createdAt = Date()

        do {
            try viewContext.save()
            print("ブックマークを追加しました: \(title)")
        } catch {
            print("ブックマーク追加エラー: \(error)")
        }
    }

    // ブックマーク一覧取得
    func fetchBookmarks() -> [Bookmark] {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Bookmark.createdAt, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("ブックマーク取得エラー: \(error)")
            return []
        }
    }

    // ブックマーク削除
    func deleteBookmark(_ bookmark: Bookmark) {
        let folder = bookmark.folder
        viewContext.delete(bookmark)

        do {
            try viewContext.save()
            print("ブックマークを削除しました")

            // 空フォルダを削除
            if let folderName = folder {
                deleteEmptyFolders()
            }
        } catch {
            print("ブックマーク削除エラー: \(error)")
        }
    }

    // URLがブックマーク済みかチェック
    func isBookmarked(url: String) -> Bool {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", url)

        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            print("ブックマークチェックエラー: \(error)")
            return false
        }
    }

    // フォルダ一覧を取得
    func fetchFolders() -> [String] {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()

        do {
            let bookmarks = try viewContext.fetch(request)
            let folders = Set(bookmarks.compactMap { $0.folder })
            return Array(folders).sorted()
        } catch {
            print("フォルダ取得エラー: \(error)")
            return []
        }
    }

    // フォルダ内のブックマーク取得
    func fetchBookmarks(inFolder folder: String) -> [Bookmark] {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.predicate = NSPredicate(format: "folder == %@", folder)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Bookmark.createdAt, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("ブックマーク取得エラー: \(error)")
            return []
        }
    }

    // ブックマークのフォルダ変更
    func moveBookmark(_ bookmark: Bookmark, toFolder folder: String) {
        bookmark.folder = folder

        do {
            try viewContext.save()
            print("ブックマークを移動しました: \(folder)")
        } catch {
            print("ブックマーク移動エラー: \(error)")
        }
    }

    // フォルダ名変更
    func renameFolder(from oldName: String, to newName: String) {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.predicate = NSPredicate(format: "folder == %@", oldName)

        do {
            let bookmarks = try viewContext.fetch(request)
            for bookmark in bookmarks {
                bookmark.folder = newName
            }
            try viewContext.save()
            print("フォルダ名を変更しました: \(oldName) -> \(newName)")
        } catch {
            print("フォルダ名変更エラー: \(error)")
        }
    }

    // フォルダ削除（中のブックマークも削除）
    func deleteFolder(_ folderName: String) {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.predicate = NSPredicate(format: "folder == %@", folderName)

        do {
            let bookmarks = try viewContext.fetch(request)
            for bookmark in bookmarks {
                viewContext.delete(bookmark)
            }
            try viewContext.save()
            print("フォルダを削除しました: \(folderName)")
        } catch {
            print("フォルダ削除エラー: \(error)")
        }
    }

    // 空フォルダを自動削除
    func deleteEmptyFolders() {
        let folders = fetchFolders()

        for folder in folders {
            let bookmarksInFolder = fetchBookmarks(inFolder: folder)

            // フォルダ内のブックマークが0件、または全て空（タイトル・URLが空）の場合は削除
            let validBookmarks = bookmarksInFolder.filter { bookmark in
                !(bookmark.title?.isEmpty ?? true) && !(bookmark.url?.isEmpty ?? true)
            }

            if validBookmarks.isEmpty {
                print("🗑️ 空フォルダを削除: \(folder)")
                deleteFolder(folder)
            }
        }
    }
}
