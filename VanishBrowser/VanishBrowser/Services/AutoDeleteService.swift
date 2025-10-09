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
            scheduleAutoDelete()
        }
    }

    @Published var deleteOnAppClose: Bool {
        didSet {
            UserDefaults.standard.set(deleteOnAppClose, forKey: "deleteOnAppClose")
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

    private var timer: Timer?

    private init() {
        // UserDefaultsから設定を読み込み
        if let modeString = UserDefaults.standard.string(forKey: "autoDeleteMode"),
           let mode = AutoDeleteMode(rawValue: modeString) {
            self.autoDeleteMode = mode
        } else {
            self.autoDeleteMode = .disabled
        }

        self.deleteOnAppClose = UserDefaults.standard.bool(forKey: "deleteOnAppClose")
        self.deleteBrowsingHistory = UserDefaults.standard.bool(forKey: "deleteBrowsingHistory")
        self.deleteDownloads = UserDefaults.standard.bool(forKey: "deleteDownloads")
        self.deleteBookmarks = UserDefaults.standard.bool(forKey: "deleteBookmarks")

        // アプリ起動時にタイマーをセット
        scheduleAutoDelete()

        // アプリがバックグラウンドに入る時の処理
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
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
        timer?.invalidate()
    }

    private func scheduleAutoDelete() {
        // 既存のタイマーをキャンセル
        timer?.invalidate()
        timer = nil

        guard let interval = autoDeleteMode.timeInterval else {
            print("⏰ 自動削除タイマー: 無効")
            return
        }

        print("⏰ 自動削除タイマー: \(autoDeleteMode.rawValue)後に削除")

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.performAutoDelete()
        }
    }

    @objc private func appWillResignActive() {
        if deleteOnAppClose {
            print("📱 アプリがバックグラウンドに移行: 自動削除実行")
            performAutoDelete()
        }
    }

    @objc private func appWillTerminate() {
        if deleteOnAppClose || autoDeleteMode == .onAppClose {
            print("📱 アプリ終了: 自動削除実行")
            performAutoDelete()
        }
    }

    func performAutoDelete() {
        print("🗑️ 自動削除開始...")

        var deletedItems: [String] = []

        // ダウンロードファイルを削除
        if deleteDownloads {
            let files = DownloadService.shared.fetchDownloadedFiles()
            for file in files {
                DownloadService.shared.deleteFile(file)
            }
            deletedItems.append("ダウンロード(\(files.count)件)")
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
