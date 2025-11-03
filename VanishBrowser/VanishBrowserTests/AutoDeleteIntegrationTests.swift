//
//  AutoDeleteIntegrationTests.swift
//  VanishBrowserTests
//
//  統合テスト: 自動削除機能の動作確認
//  - ブックマーク、履歴、ダウンロード、タブが設定通りに削除されるか検証
//

import XCTest
import CoreData
@testable import VanishBrowser

final class AutoDeleteIntegrationTests: XCTestCase {
    var service: AutoDeleteService!
    var bookmarkService: BookmarkService!
    var downloadService: DownloadService!
    var historyManager: BrowsingHistoryManager!

    override func setUpWithError() throws {
        service = AutoDeleteService.shared
        bookmarkService = BookmarkService.shared
        downloadService = DownloadService.shared
        historyManager = BrowsingHistoryManager.shared

        // テスト前にすべてクリア
        clearAllData()

        // 自動削除設定をリセット
        service.autoDeleteMode = .disabled
        service.deleteBrowsingHistory = false
        service.deleteDownloads = false
        service.deleteBookmarks = false
        service.deleteTabs = false
    }

    override func tearDownWithError() throws {
        clearAllData()
        service = nil
        bookmarkService = nil
        downloadService = nil
        historyManager = nil
    }

    private func clearAllData() {
        // すべてのデータを削除
        let bookmarks = bookmarkService.fetchBookmarks()
        for bookmark in bookmarks {
            bookmarkService.deleteBookmark(bookmark)
        }

        let downloads = downloadService.fetchDownloadedFiles()
        for download in downloads {
            downloadService.deleteFile(download)
        }

        historyManager.clearHistory()
    }

    // MARK: - ブックマーク削除テスト

    func testBookmarkDeletedWhenEnabled() throws {
        // ブックマークを作成
        bookmarkService.addBookmark(title: "Test Bookmark 1", url: "https://example.com/1")
        bookmarkService.addBookmark(title: "Test Bookmark 2", url: "https://example.com/2")

        let before = bookmarkService.fetchBookmarks().count
        XCTAssertEqual(before, 2, "ブックマークが2件作成されているはず")

        // ブックマーク削除を有効化
        service.deleteBookmarks = true
        service.performManualDelete(history: false, downloads: false, bookmarks: true, tabs: false)

        let after = bookmarkService.fetchBookmarks().count
        XCTAssertEqual(after, 0, "ブックマークが削除されているはず")
    }

    func testBookmarkNotDeletedWhenDisabled() throws {
        // ブックマークを作成
        bookmarkService.addBookmark(title: "Test Bookmark 1", url: "https://example.com/1")
        bookmarkService.addBookmark(title: "Test Bookmark 2", url: "https://example.com/2")

        let before = bookmarkService.fetchBookmarks().count
        XCTAssertEqual(before, 2, "ブックマークが2件作成されているはず")

        // ブックマーク削除を無効化
        service.deleteBookmarks = false
        service.performManualDelete(history: false, downloads: false, bookmarks: false, tabs: false)

        let after = bookmarkService.fetchBookmarks().count
        XCTAssertEqual(after, 2, "ブックマークが削除されていないはず")
    }

    // MARK: - ダウンロード削除テスト

    func testDownloadDeletedWhenEnabled() throws {
        // テスト用ダウンロードファイルを作成
        let testURL = FileManager.default.temporaryDirectory.appendingPathComponent("test1.txt")
        try "Test Content 1".write(to: testURL, atomically: true, encoding: .utf8)

        downloadService.saveDownloadedFile(
            fileName: "test1.txt",
            filePath: testURL.path,
            fileSize: 100,
            mimeType: "text/plain",
            folder: nil
        )

        let before = downloadService.fetchDownloadedFiles().count
        XCTAssertEqual(before, 1, "ダウンロードファイルが1件作成されているはず")

        // ダウンロード削除を有効化
        service.deleteDownloads = true
        service.performManualDelete(history: false, downloads: true, bookmarks: false, tabs: false)

        let after = downloadService.fetchDownloadedFiles().count
        XCTAssertEqual(after, 0, "ダウンロードファイルが削除されているはず")
    }

    func testDownloadNotDeletedWhenDisabled() throws {
        // テスト用ダウンロードファイルを作成
        let testURL = FileManager.default.temporaryDirectory.appendingPathComponent("test2.txt")
        try "Test Content 2".write(to: testURL, atomically: true, encoding: .utf8)

        downloadService.saveDownloadedFile(
            fileName: "test2.txt",
            filePath: testURL.path,
            fileSize: 100,
            mimeType: "text/plain",
            folder: nil
        )

        let before = downloadService.fetchDownloadedFiles().count
        XCTAssertEqual(before, 1, "ダウンロードファイルが1件作成されているはず")

        // ダウンロード削除を無効化
        service.deleteDownloads = false
        service.performManualDelete(history: false, downloads: false, bookmarks: false, tabs: false)

        let after = downloadService.fetchDownloadedFiles().count
        XCTAssertEqual(after, 1, "ダウンロードファイルが削除されていないはず")
    }

    // MARK: - 履歴削除テスト

    func testHistoryDeletedWhenEnabled() throws {
        // 履歴を作成
        historyManager.addHistory(url: "https://example.com/page1", title: "Page 1")
        historyManager.addHistory(url: "https://example.com/page2", title: "Page 2")

        let before = historyManager.fetchHistory().count
        XCTAssertEqual(before, 2, "履歴が2件作成されているはず")

        // 履歴削除を有効化
        service.deleteBrowsingHistory = true
        service.performManualDelete(history: true, downloads: false, bookmarks: false, tabs: false)

        let after = historyManager.fetchHistory().count
        XCTAssertEqual(after, 0, "履歴が削除されているはず")
    }

    func testHistoryNotDeletedWhenDisabled() throws {
        // 履歴を作成
        historyManager.addHistory(url: "https://example.com/page1", title: "Page 1")
        historyManager.addHistory(url: "https://example.com/page2", title: "Page 2")

        let before = historyManager.fetchHistory().count
        XCTAssertEqual(before, 2, "履歴が2件作成されているはず")

        // 履歴削除を無効化
        service.deleteBrowsingHistory = false
        service.performManualDelete(history: false, downloads: false, bookmarks: false, tabs: false)

        let after = historyManager.fetchHistory().count
        XCTAssertEqual(after, 2, "履歴が削除されていないはず")
    }

    // MARK: - 複合テスト

    func testMultipleItemsDeleted() throws {
        // ブックマーク、ダウンロード、履歴を作成
        bookmarkService.addBookmark(title: "Test Bookmark", url: "https://example.com")

        let testURL = FileManager.default.temporaryDirectory.appendingPathComponent("test3.txt")
        try "Test Content 3".write(to: testURL, atomically: true, encoding: .utf8)
        downloadService.saveDownloadedFile(
            fileName: "test3.txt",
            filePath: testURL.path,
            fileSize: 100,
            mimeType: "text/plain",
            folder: nil
        )

        historyManager.addHistory(url: "https://example.com/page", title: "Page")

        // すべて削除を有効化
        service.deleteBookmarks = true
        service.deleteDownloads = true
        service.deleteBrowsingHistory = true
        service.performManualDelete(history: true, downloads: true, bookmarks: true, tabs: false)

        XCTAssertEqual(bookmarkService.fetchBookmarks().count, 0, "ブックマークが削除されているはず")
        XCTAssertEqual(downloadService.fetchDownloadedFiles().count, 0, "ダウンロードが削除されているはず")
        XCTAssertEqual(historyManager.fetchHistory().count, 0, "履歴が削除されているはず")
    }

    func testSelectiveDelete() throws {
        // ブックマーク、ダウンロード、履歴を作成
        bookmarkService.addBookmark(title: "Test Bookmark", url: "https://example.com")

        let testURL = FileManager.default.temporaryDirectory.appendingPathComponent("test4.txt")
        try "Test Content 4".write(to: testURL, atomically: true, encoding: .utf8)
        downloadService.saveDownloadedFile(
            fileName: "test4.txt",
            filePath: testURL.path,
            fileSize: 100,
            mimeType: "text/plain",
            folder: nil
        )

        historyManager.addHistory(url: "https://example.com/page", title: "Page")

        // ブックマークと履歴のみ削除、ダウンロードは残す
        service.deleteBookmarks = true
        service.deleteDownloads = false
        service.deleteBrowsingHistory = true
        service.performManualDelete(history: true, downloads: false, bookmarks: true, tabs: false)

        XCTAssertEqual(bookmarkService.fetchBookmarks().count, 0, "ブックマークが削除されているはず")
        XCTAssertEqual(downloadService.fetchDownloadedFiles().count, 1, "ダウンロードが残っているはず")
        XCTAssertEqual(historyManager.fetchHistory().count, 0, "履歴が削除されているはず")
    }

    // MARK: - 自動削除モード設定テスト

    func testAutoDeleteModeSettings() throws {
        // 各種モードが正しく設定できるか確認
        service.autoDeleteMode = .disabled
        XCTAssertEqual(service.autoDeleteMode, .disabled)

        service.autoDeleteMode = .onAppClose
        XCTAssertEqual(service.autoDeleteMode, .onAppClose)

        service.autoDeleteMode = .after1Hour
        XCTAssertEqual(service.autoDeleteMode, .after1Hour)

        service.autoDeleteMode = .after24Hours
        XCTAssertEqual(service.autoDeleteMode, .after24Hours)

        service.autoDeleteMode = .after7Days
        XCTAssertEqual(service.autoDeleteMode, .after7Days)

        service.autoDeleteMode = .after30Days
        XCTAssertEqual(service.autoDeleteMode, .after30Days)

        service.autoDeleteMode = .after90Days
        XCTAssertEqual(service.autoDeleteMode, .after90Days)
    }

    func testDeleteTargetToggles() throws {
        // 各削除対象の設定が正しく動作するか確認
        service.deleteBrowsingHistory = true
        XCTAssertTrue(service.deleteBrowsingHistory)

        service.deleteBrowsingHistory = false
        XCTAssertFalse(service.deleteBrowsingHistory)

        service.deleteDownloads = true
        XCTAssertTrue(service.deleteDownloads)

        service.deleteDownloads = false
        XCTAssertFalse(service.deleteDownloads)

        service.deleteBookmarks = true
        XCTAssertTrue(service.deleteBookmarks)

        service.deleteBookmarks = false
        XCTAssertFalse(service.deleteBookmarks)

        service.deleteTabs = true
        XCTAssertTrue(service.deleteTabs)

        service.deleteTabs = false
        XCTAssertFalse(service.deleteTabs)
    }
}
