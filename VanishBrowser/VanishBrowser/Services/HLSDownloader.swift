//
//  HLSDownloader.swift
//  VanishBrowser
//
//  HLS動画のセグメントダウンロード＆結合機能
//

import Foundation
import Combine
import AVFoundation
import UIKit
import CoreVideo

class HLSDownloader: NSObject, ObservableObject {
    @Published var progress: Double = 0.0
    @Published var downloadedSize: Int64 = 0
    @Published var totalSegments: Int = 0
    @Published var downloadedSegments: Int = 0
    @Published var isDownloading: Bool = false
    @Published var error: Error?

    private var downloadTask: Task<Void, Never>?
    private var currentTempFolder: URL?

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
    func downloadHLS(
        quality: HLSQuality,
        fileName: String,
        folder: String,
        progressHandler: ((Double, Int, Int, Int64) -> Void)? = nil
    ) async throws -> URL {
        print("🎬 HLSダウンロード開始: \(quality.displayName)")

        await MainActor.run {
            isDownloading = true
            progress = 0.0
            downloadedSegments = 0
        }

        defer {
            Task { @MainActor in
                isDownloading = false
            }
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
        let downloadsPath = folder.isEmpty
            ? documentsPath.appendingPathComponent("Downloads")
            : documentsPath.appendingPathComponent("Downloads").appendingPathComponent(folder)
        let videoName = fileName.replacingOccurrences(of: ".m3u8", with: "")

        // 一時作業用フォルダ（セグメント保存用）
        let hlsFolder = downloadsPath.appendingPathComponent("_temp_\(videoName)_\(UUID().uuidString)")
        currentTempFolder = hlsFolder

        try FileManager.default.createDirectory(at: hlsFolder, withIntermediateDirectories: true)
        print("📁 一時フォルダ作成: \(hlsFolder.path)")

        var segmentFiles: [String] = []

        // セグメントの種類を判定（最初のURLから）
        let firstSegmentURL = segments.first?.absoluteString ?? ""
        let isJPEGSequence = firstSegmentURL.hasSuffix(".jpeg") || firstSegmentURL.hasSuffix(".jpg")
        let fileExtension = isJPEGSequence ? ".jpeg" : ".ts"

        print("📝 検出されたセグメント形式: \(isJPEGSequence ? "JPEG画像シーケンス" : "TSビデオ")")

        // 並列ダウンロードのためのアクター
        actor DownloadProgress {
            var completed: Int = 0
            var totalSize: Int64 = 0

            func increment(size: Int64) -> (Int, Int64) {
                completed += 1
                totalSize += size
                return (completed, totalSize)
            }
        }

        let progressActor = DownloadProgress()
        let concurrentDownloads = 5 // 同時ダウンロード数

        // セグメントを並列ダウンロード
        try await withThrowingTaskGroup(of: (Int, String, Int64).self) { group in
            var activeDownloads = 0
            var nextIndex = 0

            // 初期バッチを開始
            while nextIndex < segments.count && activeDownloads < concurrentDownloads {
                let index = nextIndex
                let segmentURL = segments[index]
                nextIndex += 1
                activeDownloads += 1

                group.addTask {
                    let (data, _) = try await URLSession.shared.data(from: segmentURL)
                    let segmentFileName = "segment_\(String(format: "%04d", index))\(fileExtension)"
                    let segmentFile = hlsFolder.appendingPathComponent(segmentFileName)
                    try data.write(to: segmentFile)
                    return (index, segmentFileName, Int64(data.count))
                }
            }

            // 結果を処理し、新しいダウンロードを開始
            for try await (_, fileName, size) in group {
                segmentFiles.append(fileName)

                let (currentCount, currentSize) = await progressActor.increment(size: size)
                let currentProgress = Double(currentCount) / Double(segments.count) * 0.95

                await MainActor.run {
                    downloadedSegments = currentCount
                    downloadedSize = currentSize
                    progress = currentProgress
                }

                progressHandler?(currentProgress, currentCount, segments.count, currentSize)

                if currentCount % 10 == 0 || currentCount == segments.count {
                    print("✅ セグメント \(currentCount)/\(segments.count) 完了 (進捗: \(Int(currentProgress * 100))%)")
                }

                // 次のダウンロードを開始
                if nextIndex < segments.count {
                    let index = nextIndex
                    let segmentURL = segments[index]
                    nextIndex += 1

                    group.addTask {
                        let (data, _) = try await URLSession.shared.data(from: segmentURL)
                        let segmentFileName = "segment_\(String(format: "%04d", index))\(fileExtension)"
                        let segmentFile = hlsFolder.appendingPathComponent(segmentFileName)
                        try data.write(to: segmentFile)
                        return (index, segmentFileName, Int64(data.count))
                    }
                }
            }
        }

        // ファイル名を順番にソート
        segmentFiles.sort()

        print("📝 全\(segments.count)セグメントのダウンロード完了。MP4への変換を開始... (形式: \(isJPEGSequence ? "JPEG" : "TS"))")

        // セグメントタイプに応じて変換
        let tempMP4File: URL
        if isJPEGSequence {
            tempMP4File = try await mergeJPEGSequenceToMP4(imageNames: segmentFiles, in: hlsFolder, videoName: videoName)
        } else {
            tempMP4File = try await mergeSegmentsToMP4(segmentNames: segmentFiles, in: hlsFolder, videoName: videoName)
        }

        // Downloads直下に最終ファイルを移動
        let finalOutputPath = downloadsPath.appendingPathComponent("\(videoName).mp4")

        // 既存ファイルがあれば削除
        if FileManager.default.fileExists(atPath: finalOutputPath.path) {
            try? FileManager.default.removeItem(at: finalOutputPath)
        }

        try FileManager.default.moveItem(at: tempMP4File, to: finalOutputPath)
        print("📦 最終ファイル移動: \(finalOutputPath.path)")

        // 一時フォルダを削除
        try? FileManager.default.removeItem(at: hlsFolder)
        print("🗑️ 一時フォルダ削除完了")

        progress = 1.0

        print("✅ HLS→MP4ダウンロード完了: \(finalOutputPath.path)")
        print("📊 合計ファイルサイズ: \(downloadedSize) bytes")

        return finalOutputPath
    }

    /// TSセグメントを結合してMP4を作成
    private func mergeSegmentsToMP4(segmentNames: [String], in folder: URL, videoName: String) async throws -> URL {
        // ステップ1: TSセグメントを一時ファイルに結合
        let mergedTSPath = folder.appendingPathComponent("\(videoName)_temp.ts")
        FileManager.default.createFile(atPath: mergedTSPath.path, contents: nil)
        let mergedFileHandle = try FileHandle(forWritingTo: mergedTSPath)

        defer {
            try? mergedFileHandle.close()
        }

        print("📝 TSセグメントを結合中...")
        for segmentName in segmentNames {
            let segmentPath = folder.appendingPathComponent(segmentName)
            let segmentData = try Data(contentsOf: segmentPath)
            mergedFileHandle.write(segmentData)
        }
        try mergedFileHandle.close()
        print("✅ TSファイル結合完了: \(mergedTSPath.path)")

        // ステップ2: TSファイルを.mp4にリネーム
        let outputPath = folder.appendingPathComponent("\(videoName).mp4")

        // 既存ファイルを削除
        if FileManager.default.fileExists(atPath: outputPath.path) {
            try? FileManager.default.removeItem(at: outputPath)
        }

        try FileManager.default.moveItem(at: mergedTSPath, to: outputPath)
        print("✅ TSファイルを.mp4にリネーム: \(outputPath.path)")

        // セグメントファイルを削除
        for segmentName in segmentNames {
            let segmentPath = folder.appendingPathComponent(segmentName)
            try? FileManager.default.removeItem(at: segmentPath)
        }

        print("🎬 動画ファイル保存完了: \(outputPath.path)")
        return outputPath
    }

    /// JPEG画像シーケンスをMP4に変換（AVAssetWriter使用）
    private func mergeJPEGSequenceToMP4(imageNames: [String], in folder: URL, videoName: String) async throws -> URL {
        let outputPath = folder.appendingPathComponent("\(videoName).mp4")
        
        // 既存ファイルを削除
        if FileManager.default.fileExists(atPath: outputPath.path) {
            try? FileManager.default.removeItem(at: outputPath)
        }
        
        print("🖼️ JPEG画像シーケンスからMP4を作成中...")
        print("📊 画像数: \(imageNames.count)")

        guard let firstImagePath = imageNames.first.map({ folder.appendingPathComponent($0) }) else {
            throw NSError(domain: "HLSDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "画像ファイルが見つかりません"])
        }

        let fileData = try Data(contentsOf: firstImagePath)
        let isActuallyJPEG = fileData.count >= 3 && fileData.starts(with: [0xFF, 0xD8, 0xFF])

        if !isActuallyJPEG {
            print("⚠️ .jpeg拡張子ですが実際はビデオセグメントです。ビデオマージ処理に切り替えます")
            return try await mergeSegmentsToMP4(segmentNames: imageNames, in: folder, videoName: videoName)
        }

        print("✅ JPEG画像として検証完了")

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    guard let firstImage = UIImage(contentsOfFile: firstImagePath.path),
                          let cgImage = firstImage.cgImage else {
                        throw NSError(domain: "HLSDownloader", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "最初の画像の読み込み失敗"])
                    }
                    
                    let videoWidth = cgImage.width
                    let videoHeight = cgImage.height
                    
                    print("📐 動画解像度: \(videoWidth)x\(videoHeight)")
                    
                    // AVAssetWriterの設定
                    let writer = try AVAssetWriter(outputURL: outputPath, fileType: .mp4)
                    
                    let videoSettings: [String: Any] = [
                        AVVideoCodecKey: AVVideoCodecType.h264,
                        AVVideoWidthKey: videoWidth,
                        AVVideoHeightKey: videoHeight,
                        AVVideoCompressionPropertiesKey: [
                            AVVideoAverageBitRateKey: 3000000, // 3Mbps
                            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                        ]
                    ]
                    
                    let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                    writerInput.expectsMediaDataInRealTime = false
                    
                    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                        assetWriterInput: writerInput,
                        sourcePixelBufferAttributes: [
                            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                            kCVPixelBufferWidthKey as String: videoWidth,
                            kCVPixelBufferHeightKey as String: videoHeight
                        ]
                    )
                    
                    writer.add(writerInput)
                    writer.startWriting()
                    writer.startSession(atSourceTime: .zero)
                    
                    // 各JPEG画像をフレームとして追加
                    let frameDuration = CMTime(seconds: 4.0, preferredTimescale: 600) // 4秒/フレーム
                    var frameCount: Int64 = 0
                    
                    for (index, imageName) in imageNames.enumerated() {
                        // writerInputが準備できるまで待機
                        while !writerInput.isReadyForMoreMediaData {
                            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                        }
                        
                        let imagePath = folder.appendingPathComponent(imageName)
                        
                        guard let image = UIImage(contentsOfFile: imagePath.path),
                              let cgImage = image.cgImage else {
                            print("⚠️ 画像読み込み失敗: \(imageName)")
                            continue
                        }
                        
                        // CGImageをCVPixelBufferに変換
                        var pixelBuffer: CVPixelBuffer?
                        let options: [CFString: Any] = [
                            kCVPixelBufferCGImageCompatibilityKey: true,
                            kCVPixelBufferCGBitmapContextCompatibilityKey: true
                        ]
                        
                        let status = CVPixelBufferCreate(
                            kCFAllocatorDefault,
                            videoWidth,
                            videoHeight,
                            kCVPixelFormatType_32ARGB,
                            options as CFDictionary,
                            &pixelBuffer
                        )
                        
                        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
                            print("⚠️ PixelBuffer作成失敗: \(imageName)")
                            continue
                        }
                        
                        CVPixelBufferLockBaseAddress(buffer, [])
                        let pixelData = CVPixelBufferGetBaseAddress(buffer)
                        
                        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                        guard let context = CGContext(
                            data: pixelData,
                            width: videoWidth,
                            height: videoHeight,
                            bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                            space: rgbColorSpace,
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                        ) else {
                            CVPixelBufferUnlockBaseAddress(buffer, [])
                            print("⚠️ CGContext作成失敗: \(imageName)")
                            continue
                        }
                        
                        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: videoWidth, height: videoHeight))
                        CVPixelBufferUnlockBaseAddress(buffer, [])
                        
                        // フレームを追加
                        let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameCount))
                        let success = adaptor.append(buffer, withPresentationTime: presentationTime)
                        
                        if !success {
                            print("⚠️ フレーム追加失敗: \(imageName)")
                        }
                        
                        frameCount += 1
                        
                        // 進捗表示（10枚ごと）
                        if index % 10 == 0 {
                            let progress = Double(index) / Double(imageNames.count) * 100
                            print("🎬 MP4変換中: \(index)/\(imageNames.count) (\(Int(progress))%)")
                        }
                        
                        // 画像ファイルを削除（メモリ節約）
                        try? FileManager.default.removeItem(at: imagePath)
                    }
                    
                    // 書き込み完了
                    writerInput.markAsFinished()
                    await writer.finishWriting()
                    
                    if writer.status == .completed {
                        print("✅ JPEG→MP4変換成功: \(outputPath.path)")
                        continuation.resume(returning: outputPath)
                    } else if let error = writer.error {
                        print("❌ JPEG→MP4変換失敗: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        print("❌ JPEG→MP4変換失敗: 不明なエラー")
                        continuation.resume(throwing: NSError(
                            domain: "HLSDownloader",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "MP4変換失敗"]
                        ))
                    }
                } catch {
                    print("❌ JPEG→MP4変換エラー: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// ダウンロードをキャンセル
    func cancel() {
        print("🛑 ダウンロードキャンセル要求")
        downloadTask?.cancel()
        isDownloading = false

        // 一時フォルダを削除
        if let tempFolder = currentTempFolder {
            try? FileManager.default.removeItem(at: tempFolder)
            print("🗑️ 一時フォルダ削除: \(tempFolder.lastPathComponent)")
            currentTempFolder = nil
        }

        // 状態をリセット
        progress = 0.0
        downloadedSegments = 0
        totalSegments = 0
        downloadedSize = 0
    }
}
