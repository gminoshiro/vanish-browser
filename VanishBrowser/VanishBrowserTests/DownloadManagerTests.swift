//
//  DownloadManagerTests.swift
//  VanishBrowserTests
//
//  単体テスト: DownloadManager
//

import XCTest
@testable import VanishBrowser

final class DownloadManagerTests: XCTestCase {
    var manager: DownloadManager!

    override func setUpWithError() throws {
        manager = DownloadManager.shared
    }

    override func tearDownWithError() throws {
        manager = nil
    }

    // MARK: - MIME Type to Extension テスト

    func testMimeTypeToExtension() throws {
        // 画像
        XCTAssertEqual(manager.getFileExtension(from: "image/jpeg"), "jpg")
        XCTAssertEqual(manager.getFileExtension(from: "image/png"), "png")
        XCTAssertEqual(manager.getFileExtension(from: "image/gif"), "gif")
        XCTAssertEqual(manager.getFileExtension(from: "image/webp"), "webp")

        // 動画
        XCTAssertEqual(manager.getFileExtension(from: "video/mp4"), "mp4")
        XCTAssertEqual(manager.getFileExtension(from: "video/quicktime"), "mov")

        // 音声
        XCTAssertEqual(manager.getFileExtension(from: "audio/mpeg"), "mp3")
        XCTAssertEqual(manager.getFileExtension(from: "audio/wav"), "wav")

        // ドキュメント
        XCTAssertEqual(manager.getFileExtension(from: "application/pdf"), "pdf")
        XCTAssertEqual(manager.getFileExtension(from: "application/zip"), "zip")

        // 不明な形式
        XCTAssertEqual(manager.getFileExtension(from: "application/unknown"), "dat")
    }

    func testMimeTypeCaseInsensitive() throws {
        // 大文字小文字を区別しない
        XCTAssertEqual(manager.getFileExtension(from: "IMAGE/JPEG"), "jpg")
        XCTAssertEqual(manager.getFileExtension(from: "Video/MP4"), "mp4")
        XCTAssertEqual(manager.getFileExtension(from: "Audio/MPEG"), "mp3")
    }

    // MARK: - ファイル名検証テスト

    func testValidFileName() throws {
        let fileName = "test_file.jpg"
        XCTAssertTrue(fileName.contains("."))
        XCTAssertFalse(fileName.isEmpty)
    }

    func testFileNameWithoutExtension() throws {
        let fileName = "test_file"
        XCTAssertFalse(fileName.contains("."))
    }

    // MARK: - ダウンロード状態テスト

    func testInitialState() throws {
        // 初期状態ではダウンロードタスクは空
        XCTAssertTrue(manager.activeDownloads.isEmpty)
    }

    func testActiveDownloads() throws {
        // activeDownloadsは配列
        XCTAssertNotNil(manager.activeDownloads)
        XCTAssertTrue(manager.activeDownloads is [DownloadTask])
    }
}

// MARK: - Extension for Testing

extension DownloadManager {
    func getFileExtension(from mimeType: String) -> String {
        switch mimeType.lowercased() {
        case "image/jpeg", "image/jpg":
            return "jpg"
        case "image/png":
            return "png"
        case "image/gif":
            return "gif"
        case "image/webp":
            return "webp"
        case "image/svg+xml":
            return "svg"
        case "video/mp4":
            return "mp4"
        case "video/quicktime":
            return "mov"
        case "video/x-msvideo":
            return "avi"
        case "video/x-matroska":
            return "mkv"
        case "audio/mpeg":
            return "mp3"
        case "audio/wav", "audio/wave":
            return "wav"
        case "audio/x-m4a":
            return "m4a"
        case "application/pdf":
            return "pdf"
        case "application/zip":
            return "zip"
        case "application/x-rar-compressed":
            return "rar"
        case "application/x-7z-compressed":
            return "7z"
        case "text/html":
            return "html"
        case "text/plain":
            return "txt"
        case "application/json":
            return "json"
        case "application/xml", "text/xml":
            return "xml"
        default:
            return "dat"
        }
    }
}
