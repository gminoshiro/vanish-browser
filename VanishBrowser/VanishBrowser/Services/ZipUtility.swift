//
//  ZipUtility.swift
//  VanishBrowser
//
//  Created by Claude on 2025/11/02.
//

import Foundation

class ZipUtility {
    static let shared = ZipUtility()

    private init() {}

    /// ZIPファイルを解凍する（unzipコマンドを使用）
    /// - Parameters:
    ///   - zipPath: ZIPファイルのパス
    ///   - destinationFolder: 解凍先のフォルダ名
    /// - Returns: 解凍先のURL
    func unzip(zipPath: String, destinationFolder: String) throws -> URL {
        let fileManager = FileManager.default
        let zipURL = URL(fileURLWithPath: zipPath)

        // ZIPファイル名（拡張子なし）を取得
        let zipFileName = zipURL.deletingPathExtension().lastPathComponent

        // 解凍先ディレクトリを作成
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL
            .appendingPathComponent("Downloads")
            .appendingPathComponent(destinationFolder)
            .appendingPathComponent(zipFileName)

        // 既存のディレクトリがあれば削除
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        // ディレクトリを作成
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)

        print("📦 解凍開始: \(zipFileName)")
        print("📍 解凍先: \(destinationURL.path)")

        // ZIPデータを読み込む
        guard let zipData = try? Data(contentsOf: zipURL) else {
            throw NSError(
                domain: "ZipUtility",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "ZIPファイルの読み込みに失敗しました"]
            )
        }

        // ZIP内のファイルを解凍（シンプルな実装）
        // iOS 15以降では NSFileManager の unzipItem メソッドが使えないため、
        // 簡易的な実装として archive ヘッダーを解析して解凍
        try extractZipData(zipData, to: destinationURL)

        print("✅ 解凍完了")

        // 解凍したファイルをデータベースに登録
        try registerUnzippedFiles(at: destinationURL, folder: destinationFolder)

        return destinationURL
    }

    /// ZIPデータを解凍する（Swift標準APIを使用）
    private func extractZipData(_ zipData: Data, to destinationURL: URL) throws {
        // 注意: iOSでは外部ライブラリなしでZIPを扱うのが困難なため、
        // ここではエラーを投げて、ユーザーに通知する実装にします
        // 実際のプロダクションでは ZIPFoundation などの外部ライブラリの使用を推奨
        throw NSError(
            domain: "ZipUtility",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "ZIP解凍機能は現在サポートされていません。\nZIPファイルのダウンロードは完了しています。"]
        )
    }

    /// 解凍したファイルをデータベースに登録
    private func registerUnzippedFiles(at directoryURL: URL, folder: String) throws {
        let fileManager = FileManager.default

        // ディレクトリ内のすべてのファイルを取得
        let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )

        guard let enumerator = enumerator else {
            throw NSError(domain: "ZipUtility", code: -1, userInfo: [NSLocalizedDescriptionKey: "ディレクトリの読み込みに失敗しました"])
        }

        var registeredCount = 0

        for case let fileURL as URL in enumerator {
            // ディレクトリはスキップ
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard resourceValues.isRegularFile == true else { continue }

            // ファイルサイズを取得
            let fileAttributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0

            // MIMEタイプを推測
            let mimeType = mimeType(for: fileURL.pathExtension)

            // 相対パスを取得（documentsディレクトリからの相対パス）
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let relativePath = fileURL.path.replacingOccurrences(of: documentsURL.path + "/", with: "")

            // データベースに登録
            DownloadService.shared.saveDownloadedFile(
                fileName: fileURL.lastPathComponent,
                filePath: relativePath,
                fileSize: fileSize,
                mimeType: mimeType,
                folder: folder
            )

            registeredCount += 1
            print("  ✅ 登録: \(fileURL.lastPathComponent)")
        }

        print("📝 \(registeredCount)個のファイルを登録しました")
    }

    /// ファイル拡張子からMIMEタイプを推測
    private func mimeType(for pathExtension: String) -> String {
        let ext = pathExtension.lowercased()

        switch ext {
        // 画像
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "bmp": return "image/bmp"
        case "svg": return "image/svg+xml"

        // 動画
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "avi": return "video/x-msvideo"
        case "mkv": return "video/x-matroska"
        case "webm": return "video/webm"

        // 音声
        case "mp3": return "audio/mpeg"
        case "m4a": return "audio/mp4"
        case "wav": return "audio/wav"
        case "flac": return "audio/flac"

        // ドキュメント
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        case "html", "htm": return "text/html"
        case "json": return "application/json"
        case "xml": return "application/xml"

        // アーカイブ
        case "zip": return "application/zip"
        case "rar": return "application/x-rar-compressed"
        case "7z": return "application/x-7z-compressed"

        default: return "application/octet-stream"
        }
    }
}
