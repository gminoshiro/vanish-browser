//
//  AutoDeleteService.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import Foundation
import Combine
import WebKit
import UIKit

enum AutoDeleteMode: String, CaseIterable {
    case disabled = "無効"
    case onAppClose = "アプリ終了時"
    case after1Hour = "1時間後"
    case after24Hours = "24時間後"
    case after3Days = "3日後"
    case after7Days = "7日後"
    case after30Days = "30日後"
    case after90Days = "90日後"

    var timeInterval: TimeInterval? {
        switch self {
        case .disabled, .onAppClose:
            return nil
        case .after1Hour:
            return 60 * 60
        case .after24Hours:
            return 24 * 60 * 60
        case .after3Days:
            return 3 * 24 * 60 * 60
        case .after7Days:
            return 7 * 24 * 60 * 60
        case .after30Days:
            return 30 * 24 * 60 * 60
        case .after90Days:
            return 90 * 24 * 60 * 60
        }
    }
}

class AutoDeleteService: ObservableObject {
    static let shared = AutoDeleteService()

    @Published var autoDeleteMode: AutoDeleteMode {
        didSet {
            UserDefaults.standard.set(autoDeleteMode.rawValue, forKey: "autoDeleteMode")
            UserDefaults.standard.synchronize()
            print("💾 設定保存: autoDeleteMode = \(autoDeleteMode.rawValue)")
        }
    }

    @Published var deleteBrowsingHistory: Bool {
        didSet {
            UserDefaults.standard.set(deleteBrowsingHistory, forKey: "deleteBrowsingHistory")
            UserDefaults.standard.synchronize()
            print("💾 設定保存: deleteBrowsingHistory = \(deleteBrowsingHistory)")
        }
    }

    @Published var deleteDownloads: Bool {
        didSet {
            UserDefaults.standard.set(deleteDownloads, forKey: "deleteDownloads")
            UserDefaults.standard.synchronize()
            print("💾 設定保存: deleteDownloads = \(deleteDownloads)")
        }
    }

    @Published var deleteBookmarks: Bool {
        didSet {
            UserDefaults.standard.set(deleteBookmarks, forKey: "deleteBookmarks")
            UserDefaults.standard.synchronize()
            print("💾 設定保存: deleteBookmarks = \(deleteBookmarks)")
        }
    }

    private init() {
        // UserDefaultsから設定を読み込み
        if let modeString = UserDefaults.standard.string(forKey: "autoDeleteMode") {
            // 旧設定のマイグレーション
            let migratedMode = AutoDeleteService.migrateOldMode(modeString)
            self.autoDeleteMode = migratedMode
            if migratedMode.rawValue != modeString {
                print("🔄 設定マイグレーション: \(modeString) → \(migratedMode.rawValue)")
                UserDefaults.standard.set(migratedMode.rawValue, forKey: "autoDeleteMode")
            }
        } else {
            self.autoDeleteMode = .disabled
        }

        // 初回起動かどうかをチェック
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

        if isFirstLaunch {
            // 初回起動時はデフォルト値を設定
            self.deleteBrowsingHistory = false
            self.deleteDownloads = false
            self.deleteBookmarks = false
            UserDefaults.standard.set(false, forKey: "deleteBrowsingHistory")
            UserDefaults.standard.set(false, forKey: "deleteDownloads")
            UserDefaults.standard.set(false, forKey: "deleteBookmarks")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            print("🎉 初回起動: デフォルト設定を保存")
        } else {
            // 既存の設定を読み込み
            self.deleteBrowsingHistory = UserDefaults.standard.bool(forKey: "deleteBrowsingHistory")
            self.deleteDownloads = UserDefaults.standard.bool(forKey: "deleteDownloads")
            self.deleteBookmarks = UserDefaults.standard.bool(forKey: "deleteBookmarks")
            print("📱 設定読み込み: 閲覧履歴=\(deleteBrowsingHistory), DL=\(deleteDownloads), BM=\(deleteBookmarks)")
        }

        // アプリがバックグラウンドに入る時の処理
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        // アプリがフォアグラウンドに戻る時の処理
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // アプリが終了する時の処理
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appWillResignActive() {
        // 最終起動時刻を保存
        UserDefaults.standard.set(Date(), forKey: "lastActiveDate")
        print("⏰ 最終起動時刻を保存: \(Date())")

        // アプリ終了時の即座削除
        if autoDeleteMode == .onAppClose {
            print("📱 アプリがバックグラウンドに移行: 自動削除実行")
            performAutoDelete()
        }
    }

    @objc private func appDidBecomeActive() {
        // アプリ起動時に経過時間をチェック
        checkAndDeleteIfNeeded()
    }

    @objc private func appWillTerminate() {
        if autoDeleteMode == .onAppClose {
            print("📱 アプリ終了: 自動削除実行")
            performAutoDelete()
        }
    }

    private func checkAndDeleteIfNeeded() {
        // 自動削除が無効な場合はチェックしない
        guard let interval = autoDeleteMode.timeInterval else {
            print("⏰ 自動削除: 無効")
            return
        }

        // 最終起動時刻を取得
        guard let lastActiveDate = UserDefaults.standard.object(forKey: "lastActiveDate") as? Date else {
            print("⏰ 最終起動時刻が未設定")
            return
        }

        // 経過時間を計算
        let elapsed = Date().timeIntervalSince(lastActiveDate)
        let days = Int(elapsed) / (24 * 3600)
        let hours = (Int(elapsed) % (24 * 3600)) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        print("⏰ 経過時間: \(days)日\(hours)時間\(minutes)分")

        // 指定時間を超えていたら削除
        if elapsed >= interval {
            let intervalDays = Int(interval) / (24 * 3600)
            let intervalHours = Int(interval) / 3600
            if intervalDays > 0 {
                print("🗑️ 自動削除条件を満たしました: \(intervalDays)日経過")
            } else {
                print("🗑️ 自動削除条件を満たしました: \(intervalHours)時間経過")
            }
            performAutoDelete()
            // 削除後、最終起動時刻をリセット
            UserDefaults.standard.set(Date(), forKey: "lastActiveDate")
        } else {
            let remaining = interval - elapsed
            let remainingDays = Int(remaining) / (24 * 3600)
            let remainingHours = (Int(remaining) % (24 * 3600)) / 3600
            let remainingMinutes = (Int(remaining) % 3600) / 60
            if remainingDays > 0 {
                print("⏰ 削除まで残り: \(remainingDays)日\(remainingHours)時間")
            } else {
                print("⏰ 削除まで残り: \(remainingHours)時間\(remainingMinutes)分")
            }
        }
    }

    func performAutoDelete() {
        print("🗑️ 自動削除開始...")
        print("📋 削除対象設定:")
        print("  - 閲覧履歴: \(deleteBrowsingHistory ? "ON" : "OFF")")
        print("  - ダウンロード: \(deleteDownloads ? "ON" : "OFF")")
        print("  - ブックマーク: \(deleteBookmarks ? "ON" : "OFF")")

        var deletedItems: [String] = []

        // 削除対象がすべてOFFの場合は警告
        if !deleteBrowsingHistory && !deleteDownloads && !deleteBookmarks {
            print("⚠️ 削除対象が選択されていません")
            return
        }

        // ダウンロードファイルを削除
        if deleteDownloads {
            let files = DownloadService.shared.fetchDownloadedFiles()
            for file in files {
                DownloadService.shared.deleteFile(file)
            }
            deletedItems.append("ダウンロード(\(files.count)件)")

            // すべてのフォルダを削除（空でないフォルダも含む）
            DownloadService.shared.removeAllFolders()
        }

        // ブックマークを削除
        if deleteBookmarks {
            let bookmarks = BookmarkService.shared.fetchBookmarks()
            for bookmark in bookmarks {
                BookmarkService.shared.deleteBookmark(bookmark)
            }
            deletedItems.append("ブックマーク(\(bookmarks.count)件)")
        }

        // 閲覧履歴を削除（WebKitのデータストア）
        if deleteBrowsingHistory {
            clearBrowsingData()
            deletedItems.append("閲覧履歴")
        }

        if !deletedItems.isEmpty {
            print("✅ 削除完了: \(deletedItems.joined(separator: ", "))")
        } else {
            print("⚠️ 削除対象なし")
        }
    }

    private func clearBrowsingData() {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()

        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            dataStore.removeData(ofTypes: dataTypes, for: records) {
                print("🧹 ブラウジングデータ削除完了")
            }
        }
    }

    // 手動削除（選択された項目のみ）
    func performManualDelete(history: Bool, downloads: Bool, bookmarks: Bool) {
        print("🗑️ 手動削除開始...")
        print("📋 削除対象:")
        print("  - 閲覧履歴: \(history ? "ON" : "OFF")")
        print("  - ダウンロード: \(downloads ? "ON" : "OFF")")
        print("  - ブックマーク: \(bookmarks ? "ON" : "OFF")")

        var deletedItems: [String] = []

        // 削除対象がすべてOFFの場合は警告
        if !history && !downloads && !bookmarks {
            print("⚠️ 削除対象が選択されていません")
            return
        }

        // ダウンロードファイルを削除
        if downloads {
            let files = DownloadService.shared.fetchDownloadedFiles()
            for file in files {
                DownloadService.shared.deleteFile(file)
            }
            deletedItems.append("ダウンロード(\(files.count)件)")

            // すべてのフォルダを削除（空でないフォルダも含む）
            DownloadService.shared.removeAllFolders()
        }

        // ブックマークを削除
        if bookmarks {
            let bookmarks = BookmarkService.shared.fetchBookmarks()
            for bookmark in bookmarks {
                BookmarkService.shared.deleteBookmark(bookmark)
            }
            deletedItems.append("ブックマーク(\(bookmarks.count)件)")
        }

        // 閲覧履歴を削除（WebKitのデータストア）
        if history {
            clearBrowsingData()
            deletedItems.append("閲覧履歴")
        }

        if !deletedItems.isEmpty {
            print("✅ 削除完了: \(deletedItems.joined(separator: ", "))")
        } else {
            print("⚠️ 削除対象なし")
        }
    }

    // 手動削除（すべてのデータを削除）
    func deleteAllData() {
        print("🗑️ deleteAllData: すべてのデータを完全削除します")

        deleteDownloads = true
        deleteBookmarks = true
        deleteBrowsingHistory = true
        performAutoDelete()

        // 一時フォルダも含めてすべてのフォルダを強制削除
        DownloadService.shared.removeAllFolders()
    }

    // 次回削除までの残り時間を取得
    func getTimeUntilNextDelete() -> String {
        guard let interval = autoDeleteMode.timeInterval else {
            return "無効"
        }

        let days = Int(interval) / (24 * 3600)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if days > 0 {
            return "\(days)日"
        } else if hours > 0 {
            return "\(hours)時間"
        } else if minutes > 0 {
            return "\(minutes)分"
        } else {
            return "まもなく"
        }
    }

    // 旧設定から新設定へのマイグレーション
    private static func migrateOldMode(_ oldModeString: String) -> AutoDeleteMode {
        // 新しいenumに存在する場合はそのまま使用
        if let mode = AutoDeleteMode(rawValue: oldModeString) {
            return mode
        }

        // 旧設定のマイグレーション
        switch oldModeString {
        case "5分後", "10分後", "30分後":
            return .after1Hour
        case "3時間後", "6時間後":
            return .after24Hours
        default:
            return .disabled
        }
    }
}
