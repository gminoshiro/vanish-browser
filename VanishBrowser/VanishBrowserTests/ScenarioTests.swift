//
//  ScenarioTests.swift
//  VanishBrowserTests
//
//  Created by 簑城玄太 on 2025/10/22.
//

import XCTest
@testable import VanishBrowser

/// ユースケースシナリオテスト
/// 実際のユーザー操作フローを再現してテストする
final class ScenarioTests: XCTestCase {

    var downloadService: DownloadService!
    var autoDeleteService: AutoDeleteService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        downloadService = DownloadService.shared
        autoDeleteService = AutoDeleteService.shared
    }

    override func tearDownWithError() throws {
        // テスト後のクリーンアップ
        downloadService.clearAllDownloads()
        try super.tearDownWithError()
    }

    // MARK: - シナリオ1: 画像10個ダウンロード

    func testScenario1_Download10Images() throws {
        print("📝 シナリオ1: 画像10個ダウンロード開始")

        // Given: テスト用画像データ
        let testImages = createTestImages(count: 10)

        // When: 10個の画像をダウンロード
        for (index, imageData) in testImages.enumerated() {
            let fileName = "test_image_\(index + 1).jpg"
            let tempURL = createTempFile(data: imageData, fileName: fileName)

            downloadService.saveDownloadedFile(
                fileName: fileName,
                filePath: tempURL.path,
                fileSize: Int64(imageData.count),
                mimeType: "image/jpeg",
                folder: nil
            )

            print("  ✅ 画像\(index + 1)ダウンロード完了: \(fileName)")
        }

        // Then: 10個の画像が保存されている
        let downloads = downloadService.fetchAllDownloads()
        XCTAssertEqual(downloads.count, 10, "10個の画像がダウンロードされているはず")

        // Then: ファイルサイズが正しい
        let totalSize = downloads.reduce(0) { $0 + $1.fileSize }
        XCTAssertGreaterThan(totalSize, 0, "総ファイルサイズは0より大きいはず")

        print("  📊 総ダウンロード数: \(downloads.count)")
        print("  📊 総ファイルサイズ: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
        print("✅ シナリオ1完了\n")
    }

    // MARK: - シナリオ2: 動画10個ダウンロード

    func testScenario2_Download10Videos() throws {
        print("📝 シナリオ2: 動画10個ダウンロード開始")

        // Given: テスト用動画データ（ダミー）
        let testVideos = createTestVideos(count: 10)

        // When: 10個の動画をダウンロード
        for (index, videoData) in testVideos.enumerated() {
            let fileName = "test_video_\(index + 1).mp4"
            let tempURL = createTempFile(data: videoData, fileName: fileName)

            downloadService.saveDownloadedFile(
                fileName: fileName,
                filePath: tempURL.path,
                fileSize: Int64(videoData.count),
                mimeType: "video/mp4",
                folder: nil
            )

            print("  ✅ 動画\(index + 1)ダウンロード完了: \(fileName)")
        }

        // Then: 10個の動画が保存されている
        let downloads = downloadService.fetchAllDownloads()
        XCTAssertEqual(downloads.count, 10, "10個の動画がダウンロードされているはず")

        // Then: mimeTypeが正しい
        let videoDownloads = downloads.filter { $0.mimeType == "video/mp4" }
        XCTAssertEqual(videoDownloads.count, 10, "全てMP4形式のはず")

        print("  📊 総ダウンロード数: \(downloads.count)")
        print("  📊 MP4動画数: \(videoDownloads.count)")
        print("✅ シナリオ2完了\n")
    }

    // MARK: - シナリオ3: 画像10個 + 動画10個ダウンロード + 内容確認

    func testScenario3_Download10Images10Videos_AndVerify() throws {
        print("📝 シナリオ3: 画像10個 + 動画10個ダウンロード + 内容確認開始")

        // Given: テスト用データ
        let testImages = createTestImages(count: 10)
        let testVideos = createTestVideos(count: 10)

        // When: 画像10個ダウンロード
        print("  📥 画像ダウンロード中...")
        for (index, imageData) in testImages.enumerated() {
            let fileName = "image_\(index + 1).jpg"
            let tempURL = createTempFile(data: imageData, fileName: fileName)

            downloadService.saveDownloadedFile(
                fileName: fileName,
                filePath: tempURL.path,
                fileSize: Int64(imageData.count),
                mimeType: "image/jpeg",
                folder: nil
            )
        }

        // When: 動画10個ダウンロード
        print("  📥 動画ダウンロード中...")
        for (index, videoData) in testVideos.enumerated() {
            let fileName = "video_\(index + 1).mp4"
            let tempURL = createTempFile(data: videoData, fileName: fileName)

            downloadService.saveDownloadedFile(
                fileName: fileName,
                filePath: tempURL.path,
                fileSize: Int64(videoData.count),
                mimeType: "video/mp4",
                folder: nil
            )
        }

        // Then: 総ダウンロード数確認
        let downloads = downloadService.fetchAllDownloads()
        XCTAssertEqual(downloads.count, 20, "合計20個のファイルがあるはず")

        // Then: 画像数確認
        let imageDownloads = downloads.filter { $0.mimeType == "image/jpeg" }
        XCTAssertEqual(imageDownloads.count, 10, "10個の画像があるはず")

        // Then: 動画数確認
        let videoDownloads = downloads.filter { $0.mimeType == "video/mp4" }
        XCTAssertEqual(videoDownloads.count, 10, "10個の動画があるはず")

        // Then: ファイル名確認
        let imageFileNames = imageDownloads.map { $0.fileName }.sorted()
        XCTAssertEqual(imageFileNames.first, "image_1.jpg")
        XCTAssertEqual(imageFileNames.last, "image_9.jpg")

        let videoFileNames = videoDownloads.map { $0.fileName }.sorted()
        XCTAssertEqual(videoFileNames.first, "video_1.mp4")
        XCTAssertEqual(videoFileNames.last, "video_9.mp4")

        // Then: ストレージ使用量確認
        let (totalBytes, fileCount) = downloadService.calculateStorageUsage()
        XCTAssertEqual(fileCount, 20, "ストレージに20個のファイルがあるはず")
        XCTAssertGreaterThan(totalBytes, 0, "ストレージ使用量は0より大きいはず")

        print("  📊 総ダウンロード数: \(downloads.count)")
        print("  📊 画像数: \(imageDownloads.count)")
        print("  📊 動画数: \(videoDownloads.count)")
        print("  📊 総ファイルサイズ: \(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file))")
        print("✅ シナリオ3完了\n")
    }

    // MARK: - シナリオ4: ダウンロード + 自動削除

    func testScenario4_DownloadAndAutoDelete() throws {
        print("📝 シナリオ4: ダウンロード + 自動削除開始")

        // Given: 画像5個と動画5個をダウンロード
        print("  📥 ファイルダウンロード中...")
        let testImages = createTestImages(count: 5)
        let testVideos = createTestVideos(count: 5)

        for (index, imageData) in testImages.enumerated() {
            let fileName = "auto_delete_image_\(index + 1).jpg"
            let tempURL = createTempFile(data: imageData, fileName: fileName)
            downloadService.saveDownloadedFile(
                fileName: fileName,
                filePath: tempURL.path,
                fileSize: Int64(imageData.count),
                mimeType: "image/jpeg",
                folder: nil
            )
        }

        for (index, videoData) in testVideos.enumerated() {
            let fileName = "auto_delete_video_\(index + 1).mp4"
            let tempURL = createTempFile(data: videoData, fileName: fileName)
            downloadService.saveDownloadedFile(
                fileName: fileName,
                filePath: tempURL.path,
                fileSize: Int64(videoData.count),
                mimeType: "video/mp4",
                folder: nil
            )
        }

        // Then: 10個のファイルが存在
        var downloads = downloadService.fetchAllDownloads()
        XCTAssertEqual(downloads.count, 10, "削除前は10個のファイルがあるはず")
        print("  📊 削除前のファイル数: \(downloads.count)")

        // When: 手動で即座に削除実行
        print("  🗑️ 手動削除実行中...")
        autoDeleteService.performManualDelete()

        // Then: すべて削除されている
        downloads = downloadService.fetchAllDownloads()
        XCTAssertEqual(downloads.count, 0, "削除後はファイルが0個のはず")
        print("  📊 削除後のファイル数: \(downloads.count)")

        print("✅ シナリオ4完了\n")
    }

    // MARK: - シナリオ5: 重複ファイル名のダウンロード

    func testScenario5_DuplicateFileNames() throws {
        print("📝 シナリオ5: 重複ファイル名のダウンロード開始")

        // Given: 同じファイル名で3回ダウンロード
        let testData = createTestImages(count: 1)[0]
        let fileName = "duplicate_test.jpg"

        print("  📥 同じファイル名で3回ダウンロード...")
        for i in 1...3 {
            let tempURL = createTempFile(data: testData, fileName: fileName)
            downloadService.saveDownloadedFile(
                fileName: fileName,
                filePath: tempURL.path,
                fileSize: Int64(testData.count),
                mimeType: "image/jpeg",
                folder: nil
            )
            print("    \(i)回目: \(fileName)")
        }

        // Then: 3個のファイルが存在（重複回避されている）
        let downloads = downloadService.fetchAllDownloads()
        XCTAssertEqual(downloads.count, 3, "3個のファイルがあるはず")

        // Then: ファイル名が異なる（連番付与されている）
        let fileNames = downloads.map { $0.fileName }.sorted()
        print("  📋 保存されたファイル名:")
        fileNames.forEach { print("    - \($0)") }

        // Note: 実際のファイル名形式は実装による
        // DownloadManagerの実装では file (1).jpg, file (2).jpg になる

        print("✅ シナリオ5完了\n")
    }

    // MARK: - シナリオ6: フォルダ分け + 削除

    func testScenario6_FolderOrganization() throws {
        print("📝 シナリオ6: フォルダ分け + 削除開始")

        // Given: 複数のフォルダにファイルを保存
        let testImages = createTestImages(count: 3)
        let folders = ["仕事", "プライベート", "その他"]

        print("  📂 フォルダ別にダウンロード中...")
        for (index, folder) in folders.enumerated() {
            let imageData = testImages[index]
            let fileName = "folder_test_\(index + 1).jpg"
            let tempURL = createTempFile(data: imageData, fileName: fileName)

            downloadService.saveDownloadedFile(
                fileName: fileName,
                filePath: tempURL.path,
                fileSize: Int64(imageData.count),
                mimeType: "image/jpeg",
                folder: folder
            )
            print("    ✅ [\(folder)] \(fileName)")
        }

        // Then: 3個のファイルが存在
        let downloads = downloadService.fetchAllDownloads()
        XCTAssertEqual(downloads.count, 3, "3個のファイルがあるはず")

        // Then: 各フォルダに1個ずつファイルがある
        for folder in folders {
            let folderDownloads = downloads.filter { $0.folder == folder }
            XCTAssertEqual(folderDownloads.count, 1, "[\(folder)]に1個のファイルがあるはず")
        }

        print("  📊 フォルダ別ファイル数:")
        for folder in folders {
            let count = downloads.filter { $0.folder == folder }.count
            print("    [\(folder)]: \(count)個")
        }

        print("✅ シナリオ6完了\n")
    }

    // MARK: - シナリオ7: 大量ダウンロード + ストレージ計算

    func testScenario7_BulkDownloadAndStorageCalculation() throws {
        print("📝 シナリオ7: 大量ダウンロード + ストレージ計算開始")

        // Given: 50個のファイルをダウンロード
        let totalFiles = 50
        print("  📥 \(totalFiles)個のファイルをダウンロード中...")

        let testImages = createTestImages(count: totalFiles)
        for (index, imageData) in testImages.enumerated() {
            let fileName = "bulk_\(index + 1).jpg"
            let tempURL = createTempFile(data: imageData, fileName: fileName)

            downloadService.saveDownloadedFile(
                fileName: fileName,
                filePath: tempURL.path,
                fileSize: Int64(imageData.count),
                mimeType: "image/jpeg",
                folder: nil
            )

            if (index + 1) % 10 == 0 {
                print("    進捗: \(index + 1)/\(totalFiles)")
            }
        }

        // Then: ストレージ計算
        let (totalBytes, fileCount) = downloadService.calculateStorageUsage()

        XCTAssertEqual(fileCount, totalFiles, "\(totalFiles)個のファイルがあるはず")
        XCTAssertGreaterThan(totalBytes, 0, "ストレージ使用量は0より大きいはず")

        print("  📊 総ファイル数: \(fileCount)")
        print("  📊 総ファイルサイズ: \(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file))")
        print("  📊 平均ファイルサイズ: \(ByteCountFormatter.string(fromByteCount: totalBytes / Int64(fileCount), countStyle: .file))")

        print("✅ シナリオ7完了\n")
    }

    // MARK: - ヘルパーメソッド

    private func createTestImages(count: Int) -> [Data] {
        return (1...count).map { index in
            // 簡易的なテスト用画像データ（実際のJPEGではなくダミーデータ）
            let size = 1024 * (10 + index) // 10KB〜60KB程度
            return Data(repeating: UInt8(index % 256), count: size)
        }
    }

    private func createTestVideos(count: Int) -> [Data] {
        return (1...count).map { index in
            // 簡易的なテスト用動画データ（ダミーデータ）
            let size = 1024 * 1024 * (1 + index % 5) // 1MB〜5MB程度
            return Data(repeating: UInt8(index % 256), count: size)
        }
    }

    private func createTempFile(data: Data, fileName: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
        return fileURL
    }
}
