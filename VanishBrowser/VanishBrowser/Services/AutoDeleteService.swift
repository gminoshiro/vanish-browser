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
    case after5Minutes = "5分後"
    case after10Minutes = "10分後"
    case after30Minutes = "30分後"
    case after1Hour = "1時間後"
    case after3Hours = "3時間後"
    case after6Hours = "6時間後"
    case after24Hours = "24時間後"

    var timeInterval: TimeInterval? {
        switch self {
        case .disabled, .onAppClose:
            return nil
        case .after5Minutes:
            return 5 * 60
        case .after10Minutes:
            return 10 * 60
        case .after30Minutes:
            return 30 * 60
        case .after1Hour:
            return 60 * 60
        case .after3Hours:
            return 3 * 60 * 60
        case .after6Hours:
            return 6 * 60 * 60
        case .after24Hours:
            return 24 * 60 * 60
        }
    }
}

class AutoDeleteService: ObservableObject {
    static let shared = AutoDeleteService()

    @Published var autoDeleteMode: AutoDeleteMode {
        didSet {
            UserDefaults.standard.set(autoDeleteMode.rawValue, forKey: "autoDeleteMode")
        }
    }

    @Published var deleteBrowsingHistory: Bool {
        didSet {
            UserDefaults.standard.set(deleteBrowsingHistory, forKey: "deleteBrowsingHistory")
        }
    }

    @Published var deleteDownloads: Bool {
        didSet {
            UserDefaults.standard.set(deleteDownloads, forKey: "deleteDownloads")
        }
    }

    @Published var deleteBookmarks: Bool {
        didSet {
            UserDefaults.standard.set(deleteBookmarks, forKey: "deleteBookmarks")
        }
    }

    private init() {
        // UserDefaultsから設定を読み込み
        if let modeString = UserDefaults.standard.string(forKey: "autoDeleteMode"),
           let mode = AutoDeleteMode(rawValue: modeString) {
            self.autoDeleteMode = mode
        } else {
            self.autoDeleteMode = .disabled
        }

        self.deleteBrowsingHistory = UserDefaults.standard.bool(forKey: "deleteBrowsingHistory")
        self.deleteDownloads = UserDefaults.standard.bool(forKey: "deleteDownloads")
        self.deleteBookmarks = UserDefaults.standard.bool(forKey: "deleteBookmarks")

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
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        print("⏰ 経過時間: \(hours)時間\(minutes)分")

        // 指定時間を超えていたら削除
        if elapsed >= interval {
            print("🗑️ 自動削除条件を満たしました: \(Int(interval/3600))時間経過")
            performAutoDelete()
            // 削除後、最終起動時刻をリセット
            UserDefaults.standard.set(Date(), forKey: "lastActiveDate")
        } else {
            let remaining = interval - elapsed
            let remainingHours = Int(remaining) / 3600
            let remainingMinutes = (Int(remaining) % 3600) / 60
            print("⏰ 削除まで残り: \(remainingHours)時間\(remainingMinutes)分")
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

            // 空のフォルダを削除
            DownloadService.shared.removeEmptyFolders()
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

            // 空のフォルダを削除
            DownloadService.shared.removeEmptyFolders()
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

    // 手動削除
    func deleteAllData() {
        deleteDownloads = true
        deleteBookmarks = true
        deleteBrowsingHistory = true
        performAutoDelete()
    }

    // 次回削除までの残り時間を取得
    func getTimeUntilNextDelete() -> String {
        guard let interval = autoDeleteMode.timeInterval else {
            return "無効"
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)時間"
        } else if minutes > 0 {
            return "\(minutes)分"
        } else {
            return "まもなく"
        }
    }
}
