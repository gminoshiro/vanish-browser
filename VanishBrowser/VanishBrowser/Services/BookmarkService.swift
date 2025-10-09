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
    func addBookmark(title: String, url: String, folder: String = "未分類") {
        let bookmark = Bookmark(context: viewContext)
        bookmark.id = UUID()
        bookmark.title = title
        bookmark.url = url
        bookmark.folder = folder
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
        viewContext.delete(bookmark)

        do {
            try viewContext.save()
            print("ブックマークを削除しました")
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
}
