//
//  HLSDownloader.swift
//  VanishBrowser
//
//  HLS動画のセグメントダウンロード＆結合機能
//

import Foundation
import Combine
import AVFoundation

class HLSDownloader: NSObject, ObservableObject {
    @Published var progress: Double = 0.0
    @Published var downloadedSize: Int64 = 0
    @Published var totalSegments: Int = 0
    @Published var downloadedSegments: Int = 0
    @Published var isDownloading: Bool = false
    @Published var error: Error?

    private var downloadTask: Task<Void, Never>?

    /// HLS動画をMP4形式でダウンロード（AVAssetExportSession使用）
    func downloadHLSAsMP4(quality: HLSQuality, fileName: String, folder: String) async throws -> URL {
        print("🎬 HLS→MP4変換ダウンロード開始: \(quality.displayName)")

        isDownloading = true
        progress = 0.0

        defer {
            isDownloading = false
        }

        // AVAssetを作成
        let asset = AVURLAsset(url: quality.url)

        // エクスポート可能かチェック
        guard try await asset.load(.isExportable) else {
            throw NSError(domain: "HLSDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "この動画はエクスポートできません"])
        }

        // 出力先パスを作成
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsPath = folder.isEmpty ? documentsPath.appendingPathComponent("Downloads") : documentsPath.appendingPathComponent("Downloads").appendingPathComponent(folder)

        try FileManager.default.createDirectory(at: downloadsPath, withIntermediateDirectories: true)

        let videoName = fileName.replacingOccurrences(of: ".m3u8", with: "").replacingOccurrences(of: ".mp4", with: "")
        let outputPath = downloadsPath.appendingPathComponent("\(videoName).mp4")

        // 既存ファイルを削除
        if FileManager.default.fileExists(atPath: outputPath.path) {
            try FileManager.default.removeItem(at: outputPath)
        }

        print("📂 出力先: \(outputPath.path)")

        // AVAssetExportSessionを作成
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "HLSDownloader", code: -2, userInfo: [NSLocalizedDescriptionKey: "エクスポートセッションの作成に失敗しました"])
        }

        exportSession.outputURL = outputPath
        exportSession.outputFileType = .mp4

        // 進捗監視タスクを開始
        let progressTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    self.progress = Double(exportSession.progress)
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            }
        }

        // エクスポート実行
        await exportSession.export()

        // 進捗監視を停止
        progressTask.cancel()

        // エクスポート結果をチェック
        switch exportSession.status {
        case .completed:
            progress = 1.0
            print("✅ MP4変換完了: \(outputPath.path)")

            // ファイルサイズを取得
            if let attributes = try? FileManager.default.attributesOfItem(atPath: outputPath.path),
               let fileSize = attributes[.size] as? Int64 {
                downloadedSize = fileSize
                print("📊 ファイルサイズ: \(fileSize) bytes")
            }

            return outputPath

        case .failed:
            if let error = exportSession.error {
                print("❌ エクスポート失敗: \(error.localizedDescription)")
                throw error
            } else {
                throw NSError(domain: "HLSDownloader", code: -3, userInfo: [NSLocalizedDescriptionKey: "エクスポートに失敗しました"])
            }

        case .cancelled:
            throw NSError(domain: "HLSDownloader", code: -4, userInfo: [NSLocalizedDescriptionKey: "エクスポートがキャンセルされました"])

        default:
            throw NSError(domain: "HLSDownloader", code: -5, userInfo: [NSLocalizedDescriptionKey: "エクスポートが不明な状態で終了しました"])
        }
    }

    /// HLS動画をローカルm3u8形式でダウンロード
    func downloadHLS(quality: HLSQuality, fileName: String, folder: String) async throws -> URL {
        print("🎬 HLSダウンロード開始: \(quality.displayName)")

        isDownloading = true
        progress = 0.0
        downloadedSegments = 0

        defer {
            isDownloading = false
        }

        // セグメントリストを取得
        let segments = try await HLSParser.parseSegments(from: quality.url)
        totalSegments = segments.count

        guard !segments.isEmpty else {
            throw NSError(domain: "HLSDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "No segments found"])
        }

        print("📦 \(segments.count)個のセグメントをダウンロード開始")

        // 出力先フォルダを作成
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsPath = documentsPath.appendingPathComponent("Downloads").appendingPathComponent(folder)
        let videoName = fileName.replacingOccurrences(of: ".m3u8", with: "")
        let hlsFolder = downloadsPath.appendingPathComponent(videoName)

        try FileManager.default.createDirectory(at: hlsFolder, withIntermediateDirectories: true)
        print("📁 HLSフォルダ作成: \(hlsFolder.path)")

        var segmentFiles: [String] = []

        // セグメントを順次ダウンロード
        for (index, segmentURL) in segments.enumerated() {
            let (data, _) = try await URLSession.shared.data(from: segmentURL)

            let segmentFileName = "segment_\(String(format: "%04d", index)).ts"
            let segmentFile = hlsFolder.appendingPathComponent(segmentFileName)
            try data.write(to: segmentFile)

            segmentFiles.append(segmentFileName)
            downloadedSegments = index + 1
            downloadedSize += Int64(data.count)

            // ダウンロード進捗を95%まで
            progress = Double(index + 1) / Double(segments.count) * 0.95

            if (index + 1) % 10 == 0 || index == segments.count - 1 {
                print("✅ セグメント \(index + 1)/\(segments.count) 完了")
            }
        }

        print("📝 ローカルm3u8プレイリストを作成中...")

        // ローカルm3u8プレイリストを作成
        let m3u8File = try createLocalM3U8(segmentNames: segmentFiles, in: hlsFolder, videoName: videoName)

        progress = 1.0

        print("✅ HLSダウンロード完了: \(m3u8File.path)")
        print("📊 合計ファイルサイズ: \(downloadedSize) bytes")

        return m3u8File
    }

    /// ローカルm3u8プレイリストを作成
    private func createLocalM3U8(segmentNames: [String], in folder: URL, videoName: String) throws -> URL {
        let m3u8Path = folder.appendingPathComponent("index.m3u8")

        var m3u8Content = """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-TARGETDURATION:10
        #EXT-X-MEDIA-SEQUENCE:0

        """

        for segmentName in segmentNames {
            m3u8Content += "#EXTINF:10.0,\n"
            m3u8Content += "\(segmentName)\n"
        }

        m3u8Content += "#EXT-X-ENDLIST\n"

        try m3u8Content.write(to: m3u8Path, atomically: true, encoding: .utf8)
        print("📝 ローカルm3u8作成完了: \(m3u8Path.path)")

        return m3u8Path
    }

    /// ダウンロードをキャンセル
    func cancel() {
        downloadTask?.cancel()
        isDownloading = false
    }
}
