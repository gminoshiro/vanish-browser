//
//  AutoDeleteServiceTests.swift
//  VanishBrowserTests
//
//  単体テスト: AutoDeleteService
//

import XCTest
@testable import VanishBrowser

final class AutoDeleteServiceTests: XCTestCase {
    var service: AutoDeleteService!

    override func setUpWithError() throws {
        service = AutoDeleteService.shared
        // テスト前にデフォルト状態にリセット
        service.autoDeleteMode = .disabled
        service.deleteBrowsingHistory = true
        service.deleteDownloads = true
        service.deleteBookmarks = false
    }

    override func tearDownWithError() throws {
        service = nil
    }

    // MARK: - モード設定テスト

    func testDefaultMode() throws {
        // デフォルトは無効
        XCTAssertEqual(service.autoDeleteMode, .disabled)
    }

    func testModeChange() throws {
        service.autoDeleteMode = .onAppClose
        XCTAssertEqual(service.autoDeleteMode, .onAppClose)

        service.autoDeleteMode = .after1Hour
        XCTAssertEqual(service.autoDeleteMode, .after1Hour)
    }

    // MARK: - 削除対象設定テスト

    func testDeleteTargets() throws {
        XCTAssertTrue(service.deleteBrowsingHistory)
        XCTAssertTrue(service.deleteDownloads)
        XCTAssertFalse(service.deleteBookmarks)

        service.deleteBookmarks = true
        XCTAssertTrue(service.deleteBookmarks)
    }

    func testAllTargetsDisabled() throws {
        // すべてOFFの場合
        service.deleteBrowsingHistory = false
        service.deleteDownloads = false
        service.deleteBookmarks = false

        XCTAssertFalse(service.deleteBrowsingHistory)
        XCTAssertFalse(service.deleteDownloads)
        XCTAssertFalse(service.deleteBookmarks)
    }

    // MARK: - 経過時間計算テスト

    func testTimeIntervalCalculation() throws {
        // 1時間後
        let oneHour = service.autoDeleteMode(for: .after1Hour)
        XCTAssertEqual(oneHour, 3600) // 1時間 = 3600秒

        // 24時間後
        let twentyFourHours = service.autoDeleteMode(for: .after24Hours)
        XCTAssertEqual(twentyFourHours, 86400) // 24時間 = 86400秒

        // 6時間後
        let sixHours = service.autoDeleteMode(for: .after6Hours)
        XCTAssertEqual(sixHours, 21600) // 6時間 = 21600秒
    }

    // MARK: - 削除実行判定テスト

    func testShouldPerformAutoDelete() throws {
        // 削除タイミングが来ていない場合
        UserDefaults.standard.set(Date(), forKey: "lastActiveDate")
        service.autoDeleteMode = .after1Hour

        XCTAssertFalse(service.shouldPerformAutoDelete())
    }

    func testShouldPerformAutoDeleteExpired() throws {
        // 削除タイミングが来ている場合
        let twoHoursAgo = Date().addingTimeInterval(-7200)
        UserDefaults.standard.set(twoHoursAgo, forKey: "lastActiveDate")
        service.autoDeleteMode = .after1Hour

        XCTAssertTrue(service.shouldPerformAutoDelete())
    }

    func testShouldPerformAutoDeleteDisabled() throws {
        // 自動削除が無効の場合
        service.autoDeleteMode = .disabled

        XCTAssertFalse(service.shouldPerformAutoDelete())
    }
}

// MARK: - Helper Extensions

extension AutoDeleteService {
    func autoDeleteMode(for mode: AutoDeleteMode) -> TimeInterval {
        switch mode {
        case .disabled, .onAppClose:
            return 0
        case .after5Minutes:
            return 300
        case .after10Minutes:
            return 600
        case .after30Minutes:
            return 1800
        case .after1Hour:
            return 3600
        case .after3Hours:
            return 10800
        case .after6Hours:
            return 21600
        case .after24Hours:
            return 86400
        }
    }

    func shouldPerformAutoDelete() -> Bool {
        guard autoDeleteMode != .disabled,
              let lastActiveDate = UserDefaults.standard.object(forKey: "lastActiveDate") as? Date else {
            return false
        }

        let elapsed = Date().timeIntervalSince(lastActiveDate)
        let threshold = autoDeleteMode(for: autoDeleteMode)

        return elapsed >= threshold
    }
}
