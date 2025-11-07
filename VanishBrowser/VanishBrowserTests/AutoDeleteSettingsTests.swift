//
//  AutoDeleteSettingsTests.swift
//  VanishBrowserTests
//
//  自動削除設定のテスト
//

import XCTest
@testable import VanishBrowser

final class AutoDeleteSettingsTests: XCTestCase {
    var service: AutoDeleteService!

    override func setUpWithError() throws {
        service = AutoDeleteService.shared
    }

    override func tearDownWithError() throws {
        // テスト後にすべてOFFにリセット
        service.deleteBookmarks = false
        service.deleteDownloads = false
        service.deleteBrowsingHistory = false
        service.deleteTabs = false
        service.autoDeleteMode = .disabled
        service = nil
    }

    // MARK: - 設定の読み書きテスト

    /// テスト: ブックマーク削除設定のON/OFF切り替えが正しく動作するか
    /// 期待結果: true/falseの設定が正しく保存・取得できる
    func testBookmarkDeleteSetting() throws {
        // 初期状態を確認
        let initialSetting = service.deleteBookmarks

        // ON/OFF切り替え
        service.deleteBookmarks = true
        XCTAssertTrue(service.deleteBookmarks, "deleteBookmarksがtrueに設定されているはず")

        service.deleteBookmarks = false
        XCTAssertFalse(service.deleteBookmarks, "deleteBookmarksがfalseに設定されているはず")

        // 元に戻す
        service.deleteBookmarks = initialSetting
    }

    /// テスト: ダウンロード削除設定のON/OFF切り替えが正しく動作するか
    /// 期待結果: true/falseの設定が正しく保存・取得できる
    func testDownloadDeleteSetting() throws {
        let initialSetting = service.deleteDownloads

        service.deleteDownloads = true
        XCTAssertTrue(service.deleteDownloads, "deleteDownloadsがtrueに設定されているはず")

        service.deleteDownloads = false
        XCTAssertFalse(service.deleteDownloads, "deleteDownloadsがfalseに設定されているはず")

        service.deleteDownloads = initialSetting
    }

    /// テスト: 閲覧履歴削除設定のON/OFF切り替えが正しく動作するか
    /// 期待結果: true/falseの設定が正しく保存・取得できる
    func testHistoryDeleteSetting() throws {
        let initialSetting = service.deleteBrowsingHistory

        service.deleteBrowsingHistory = true
        XCTAssertTrue(service.deleteBrowsingHistory, "deleteBrowsingHistoryがtrueに設定されているはず")

        service.deleteBrowsingHistory = false
        XCTAssertFalse(service.deleteBrowsingHistory, "deleteBrowsingHistoryがfalseに設定されているはず")

        service.deleteBrowsingHistory = initialSetting
    }

    /// テスト: タブ削除設定のON/OFF切り替えが正しく動作するか
    /// 期待結果: true/falseの設定が正しく保存・取得できる
    func testTabDeleteSetting() throws {
        let initialSetting = service.deleteTabs

        service.deleteTabs = true
        XCTAssertTrue(service.deleteTabs, "deleteTabsがtrueに設定されているはず")

        service.deleteTabs = false
        XCTAssertFalse(service.deleteTabs, "deleteTabsがfalseに設定されているはず")

        service.deleteTabs = initialSetting
    }

    // MARK: - 自動削除モードテスト

    /// テスト: 自動削除モードの各設定が正しく保存・取得できるか
    /// 期待結果: 無効/終了時/1時間後/24時間後/3日後/7日後/30日後/90日後の全モードが正しく設定できる
    func testAutoDeleteModeSettings() throws {
        let initialMode = service.autoDeleteMode

        // 各モードを設定できることを確認
        service.autoDeleteMode = .disabled
        XCTAssertEqual(service.autoDeleteMode, .disabled)

        service.autoDeleteMode = .onAppClose
        XCTAssertEqual(service.autoDeleteMode, .onAppClose)

        service.autoDeleteMode = .after1Hour
        XCTAssertEqual(service.autoDeleteMode, .after1Hour)

        service.autoDeleteMode = .after24Hours
        XCTAssertEqual(service.autoDeleteMode, .after24Hours)

        service.autoDeleteMode = .after3Days
        XCTAssertEqual(service.autoDeleteMode, .after3Days)

        service.autoDeleteMode = .after7Days
        XCTAssertEqual(service.autoDeleteMode, .after7Days)

        service.autoDeleteMode = .after30Days
        XCTAssertEqual(service.autoDeleteMode, .after30Days)

        service.autoDeleteMode = .after90Days
        XCTAssertEqual(service.autoDeleteMode, .after90Days)

        // 元に戻す
        service.autoDeleteMode = initialMode
    }

    // MARK: - 複合設定テスト

    /// テスト: 複数の削除設定を同時に設定した場合に正しく動作するか
    /// 期待結果: すべてOFF、すべてON、選択的にONの各パターンで正しく設定できる
    func testMultipleSettings() throws {
        // すべてOFFの状態
        service.deleteBookmarks = false
        service.deleteDownloads = false
        service.deleteBrowsingHistory = false
        service.deleteTabs = false

        XCTAssertFalse(service.deleteBookmarks)
        XCTAssertFalse(service.deleteDownloads)
        XCTAssertFalse(service.deleteBrowsingHistory)
        XCTAssertFalse(service.deleteTabs)

        // すべてONの状態
        service.deleteBookmarks = true
        service.deleteDownloads = true
        service.deleteBrowsingHistory = true
        service.deleteTabs = true

        XCTAssertTrue(service.deleteBookmarks)
        XCTAssertTrue(service.deleteDownloads)
        XCTAssertTrue(service.deleteBrowsingHistory)
        XCTAssertTrue(service.deleteTabs)

        // 選択的にON（ブックマークと履歴のみ）
        service.deleteBookmarks = true
        service.deleteDownloads = false
        service.deleteBrowsingHistory = true
        service.deleteTabs = false

        XCTAssertTrue(service.deleteBookmarks)
        XCTAssertFalse(service.deleteDownloads)
        XCTAssertTrue(service.deleteBrowsingHistory)
        XCTAssertFalse(service.deleteTabs)
    }

    // MARK: - UserDefaults永続化テスト

    /// テスト: 設定がUserDefaultsに正しく永続化されるか
    /// 期待結果: 設定変更がUserDefaultsに保存され、キーと値が正しく取得できる
    func testSettingsPersistence() throws {
        // 設定を変更
        service.deleteBookmarks = true
        service.autoDeleteMode = .after7Days

        // UserDefaultsに保存されているか確認
        let savedBookmarks = UserDefaults.standard.bool(forKey: "deleteBookmarks")
        let savedMode = UserDefaults.standard.string(forKey: "autoDeleteMode")

        XCTAssertTrue(savedBookmarks, "deleteBookmarksがUserDefaultsに保存されているはず")
        XCTAssertEqual(savedMode, "7日後", "autoDeleteModeがUserDefaultsに保存されているはず")
    }
}
