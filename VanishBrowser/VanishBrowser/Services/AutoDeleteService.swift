//
//  AutoDeleteService.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import Foundation
import CoreData

class AutoDeleteService {
    static let shared = AutoDeleteService()

    private let viewContext = PersistenceController.shared.container.viewContext
    private let fileManager = FileManager.default

    private init() {}

    // アプリ起動時のチェック
    func checkAutoDelete(onWarning: @escaping (Int) -> Void, onDelete: @escaping () -> Void) {
        guard let lastOpenedAt = AppSettingsService.shared.getLastOpenedAt() else {
            // 初回起動
            AppSettingsService.shared.updateLastOpenedAt()
            return
        }

        let autoDeleteDays = AppSettingsService.shared.getAutoDeleteDays()
        let warningDays = AppSettingsService.shared.getDeleteWarningDays()

        let calendar = Calendar.current
        let daysSinceLastOpened = calendar.dateComponents([.day], from: lastOpenedAt, to: Date()).day ?? 0

        print("最終起動から\(daysSinceLastOpened)日経過")

        // 自動削除日数を超えた場合
        if daysSinceLastOpened >= autoDeleteDays {
            print("⚠️ 自動削除実行: \(daysSinceLastOpened)日経過")
            deleteAllData()
            onDelete()
        }
        // 警告期間内の場合
        else if daysSinceLastOpened >= (autoDeleteDays - warningDays) {
            let daysLeft = Int(autoDeleteDays) - daysSinceLastOpened
            print("⚠️ 削除警告: あと\(daysLeft)日で削除されます")
            onWarning(daysLeft)
        }

        // 最終オープン日時を更新
        AppSettingsService.shared.updateLastOpenedAt()
    }

    // 全データ削除
    func deleteAllData() {
        print("🗑️ 全データ削除を開始...")

        // 1. ダウンロードファイルを削除
        deleteAllDownloadedFiles()

        // 2. ブックマークを削除
        deleteAllBookmarks()

        // 3. ブラウジングデータを削除（WKWebViewのキャッシュなど）
        clearBrowsingData()

        print("✅ 全データ削除が完了しました")
    }

    // ダウンロードファイルを全削除
    private func deleteAllDownloadedFiles() {
        let downloads = DownloadService.shared.fetchDownloadedFiles()
        for download in downloads {
            DownloadService.shared.deleteFile(download)
        }
        print("ダウンロードファイルを削除しました: \(downloads.count)件")
    }

    // ブックマークを全削除
    private func deleteAllBookmarks() {
        let bookmarks = BookmarkService.shared.fetchBookmarks()
        for bookmark in bookmarks {
            BookmarkService.shared.deleteBookmark(bookmark)
        }
        print("ブックマークを削除しました: \(bookmarks.count)件")
    }

    // ブラウジングデータを削除
    private func clearBrowsingData() {
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)

        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: date) {
            print("ブラウジングデータを削除しました")
        }
    }

    // 削除予定日を計算
    func getDeleteDate() -> Date? {
        guard let lastOpenedAt = AppSettingsService.shared.getLastOpenedAt() else {
            return nil
        }

        let autoDeleteDays = AppSettingsService.shared.getAutoDeleteDays()
        let calendar = Calendar.current

        return calendar.date(byAdding: .day, value: Int(autoDeleteDays), to: lastOpenedAt)
    }

    // 残り日数を取得
    func getDaysUntilDelete() -> Int? {
        guard let deleteDate = getDeleteDate() else {
            return nil
        }

        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: deleteDate).day

        return days
    }
}

import WebKit
