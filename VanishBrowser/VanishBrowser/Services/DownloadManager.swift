//
//  DownloadManager.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/11.
//

import Foundation
import Combine
import CoreData
import UserNotifications

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [DownloadTask] = []

    private var session: URLSession!

    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        // 通知権限をリクエスト
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ 通知権限が許可されました")
            } else if let error = error {
                print("❌ 通知権限エラー: \(error)")
            }
        }
    }

    private func sendDownloadCompletionNotification(fileName: String) {
        let content = UNMutableNotificationContent()
        content.title = "ダウンロード完了"
        content.body = fileName
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 即座に通知
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 通知送信エラー: \(error)")
            } else {
                print("✅ 通知送信成功: \(fileName)")
            }
        }
    }

    func startDownload(url: URL, fileName: String, folder: String) {
        let downloadTask = DownloadTask(url: url, fileName: fileName, folder: folder)

        DispatchQueue.main.async {
            self.activeDownloads.append(downloadTask)
        }

        let task = session.downloadTask(with: url)
        downloadTask.task = task
        downloadTask.status = .downloading
        task.resume()

        print("📥 ダウンロード開始: \(fileName)")
    }

    func pauseDownload(_ downloadTask: DownloadTask) {
        guard let task = downloadTask.task else { return }

        task.cancel { resumeData in
            DispatchQueue.main.async {
                downloadTask.resumeData = resumeData
                downloadTask.status = .paused
                print("⏸️ ダウンロード一時停止: \(downloadTask.fileName)")
            }
        }
    }

    func resumeDownload(_ downloadTask: DownloadTask) {
        guard let resumeData = downloadTask.resumeData else {
            // resumeDataがない場合は最初からダウンロード
            startDownload(url: downloadTask.url, fileName: downloadTask.fileName, folder: downloadTask.folder)
            return
        }

        let task = session.downloadTask(withResumeData: resumeData)
        downloadTask.task = task
        downloadTask.status = .downloading
        task.resume()

        print("▶️ ダウンロード再開: \(downloadTask.fileName)")
    }

    func cancelDownload(_ downloadTask: DownloadTask) {
        if downloadTask.isHLS {
            // HLSダウンロードのキャンセル
            downloadTask.hlsTask?.cancel()

            // 一時フォルダを削除
            Task {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let downloadsPath = documentsPath.appendingPathComponent("Downloads")

                // _temp_ で始まるフォルダを探して削除
                guard let enumerator = FileManager.default.enumerator(at: downloadsPath, includingPropertiesForKeys: [.isDirectoryKey]) else {
                    return
                }

                let allFiles = enumerator.allObjects.compactMap { $0 as? URL }
                for fileURL in allFiles {
                    if fileURL.lastPathComponent.hasPrefix("_temp_") {
                        try? FileManager.default.removeItem(at: fileURL)
                        print("🗑️ 一時フォルダ削除: \(fileURL.lastPathComponent)")
                    }
                }
            }
        } else {
            // 通常ダウンロードのキャンセル
            downloadTask.task?.cancel()
        }

        DispatchQueue.main.async {
            downloadTask.status = .cancelled
            if let index = self.activeDownloads.firstIndex(where: { $0.id == downloadTask.id }) {
                self.activeDownloads.remove(at: index)
            }
            print("❌ ダウンロードキャンセル: \(downloadTask.fileName)")
        }
    }

    /// HLSダウンロード開始
    func startHLSDownload(quality: HLSQuality, fileName: String, folder: String) {
        let downloadTask = DownloadTask(
            url: quality.url,
            fileName: fileName,
            folder: folder,
            isHLS: true,
            hlsQuality: quality
        )

        DispatchQueue.main.async {
            self.activeDownloads.append(downloadTask)
            downloadTask.status = .downloading
        }

        // HLSDownloaderを使用して非同期ダウンロード
        downloadTask.hlsTask = Task {
            do {
                let hlsDownloader = HLSDownloader()

                let outputURL = try await hlsDownloader.downloadHLS(
                    quality: quality,
                    fileName: fileName,
                    folder: folder
                ) { progress, downloadedSegments, totalSegments, downloadedBytes in
                    // プログレスハンドラー - MainActorで実行
                    Task { @MainActor in
                        downloadTask.progress = Float(progress)
                        downloadTask.downloadedSegments = downloadedSegments
                        downloadTask.totalSegments = totalSegments
                        downloadTask.downloadedBytes = downloadedBytes
                    }
                }

                // ファイルサイズを取得
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64) ?? 0

                // DownloadServiceに登録
                DownloadService.shared.saveDownloadedFile(
                    fileName: outputURL.lastPathComponent,
                    filePath: outputURL.path,
                    fileSize: fileSize,
                    mimeType: "video/mp4",
                    folder: folder
                )

                await MainActor.run {
                    downloadTask.status = .completed
                    downloadTask.progress = 1.0
                    if let index = self.activeDownloads.firstIndex(where: { $0.id == downloadTask.id }) {
                        self.activeDownloads.remove(at: index)
                    }
                    self.sendDownloadCompletionNotification(fileName: fileName)
                    print("✅ HLSダウンロード完了: \(outputURL.path)")
                }

            } catch is CancellationError {
                // キャンセルされた場合はリストから削除
                await MainActor.run {
                    downloadTask.status = .cancelled
                    if let index = self.activeDownloads.firstIndex(where: { $0.id == downloadTask.id }) {
                        self.activeDownloads.remove(at: index)
                    }
                    print("❌ HLSダウンロードキャンセル: \(downloadTask.fileName)")
                }
            } catch let error as NSError {
                // エラーの場合はリストから削除
                let errorMessage: String
                if error.domain == NSURLErrorDomain {
                    switch error.code {
                    case NSURLErrorNotConnectedToInternet:
                        errorMessage = "インターネット接続がありません"
                    case NSURLErrorTimedOut:
                        errorMessage = "接続がタイムアウトしました"
                    case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                        errorMessage = "サーバーに接続できません"
                    case NSURLErrorNetworkConnectionLost:
                        errorMessage = "ネットワーク接続が切断されました"
                    default:
                        errorMessage = "ネットワークエラー: \(error.localizedDescription)"
                    }
                } else {
                    errorMessage = error.localizedDescription
                }

                await MainActor.run {
                    downloadTask.status = .failed
                    downloadTask.error = error
                    if let index = self.activeDownloads.firstIndex(where: { $0.id == downloadTask.id }) {
                        self.activeDownloads.remove(at: index)
                    }
                    print("❌ HLSダウンロード失敗: \(errorMessage)")
                }
            } catch {
                // その他のエラー
                await MainActor.run {
                    downloadTask.status = .failed
                    downloadTask.error = error
                    if let index = self.activeDownloads.firstIndex(where: { $0.id == downloadTask.id }) {
                        self.activeDownloads.remove(at: index)
                    }
                    print("❌ HLSダウンロード失敗: \(error.localizedDescription)")
                }
            }
        }

        print("📥 HLSダウンロード開始: \(fileName)")
    }

    private func findDownloadTask(for task: URLSessionTask) -> DownloadTask? {
        return activeDownloads.first { $0.task == task }
    }

    private func getFileExtension(from mimeType: String) -> String {
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
        case "video/webm":
            return "webm"
        case "audio/mpeg":
            return "mp3"
        case "audio/wav":
            return "wav"
        case "audio/ogg":
            return "ogg"
        case "application/pdf":
            return "pdf"
        case "application/zip":
            return "zip"
        case "application/x-rar-compressed":
            return "rar"
        case "text/html":
            return "html"
        case "text/plain":
            return "txt"
        case "application/json":
            return "json"
        default:
            return "dat"
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let downloadTaskObj = findDownloadTask(for: downloadTask) else { return }

        do {
            // Content-Typeから拡張子を取得
            var fileName = downloadTaskObj.fileName
            let fileExtension = (fileName as NSString).pathExtension

            if fileExtension.isEmpty {
                // 拡張子がない場合、Content-Typeから取得
                if let mimeType = downloadTask.response?.mimeType {
                    let ext = getFileExtension(from: mimeType)
                    fileName = "\(fileName).\(ext)"
                    print("📝 Content-Typeから拡張子を追加: \(mimeType) → .\(ext)")
                }
            }

            // フォルダ作成とファイル保存先URL
            let baseURL = DownloadService.shared.getDownloadsDirectory()
            let folderURL: URL

            if downloadTaskObj.folder.isEmpty {
                // フォルダ未選択：Downloadsディレクトリ直下に保存
                folderURL = baseURL
            } else {
                // フォルダ指定あり
                folderURL = baseURL.appendingPathComponent(downloadTaskObj.folder, isDirectory: true)
                if !FileManager.default.fileExists(atPath: folderURL.path) {
                    try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
                }
            }

            // 重複ファイル名を処理（file.jpg → file (1).jpg）
            var destinationURL = folderURL.appendingPathComponent(fileName)
            var counter = 1
            let nameWithoutExt = (fileName as NSString).deletingPathExtension
            let ext = (fileName as NSString).pathExtension

            while FileManager.default.fileExists(atPath: destinationURL.path) {
                let newFileName = ext.isEmpty ? "\(nameWithoutExt) (\(counter))" : "\(nameWithoutExt) (\(counter)).\(ext)"
                destinationURL = folderURL.appendingPathComponent(newFileName)
                counter += 1
            }

            // 最終的なファイル名を更新
            fileName = destinationURL.lastPathComponent

            try FileManager.default.moveItem(at: location, to: destinationURL)

            // ファイルサイズ取得
            let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            // Core Dataに保存
            DispatchQueue.main.async {
                DownloadService.shared.saveDownloadedFile(
                    fileName: fileName,
                    filePath: destinationURL.path,
                    fileSize: fileSize,
                    mimeType: nil,
                    folder: downloadTaskObj.folder.isEmpty ? nil : downloadTaskObj.folder
                )

                downloadTaskObj.status = .completed
                if let index = self.activeDownloads.firstIndex(where: { $0.id == downloadTaskObj.id }) {
                    self.activeDownloads.remove(at: index)
                }

                // ダウンロード完了通知を送信
                self.sendDownloadCompletionNotification(fileName: fileName)

                print("✅ ダウンロード完了: \(fileName)")
            }
        } catch {
            print("❌ ダウンロード保存エラー: \(error)")
            DispatchQueue.main.async {
                downloadTaskObj.status = .failed
                downloadTaskObj.error = error
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let downloadTaskObj = findDownloadTask(for: downloadTask) else { return }

        DispatchQueue.main.async {
            downloadTaskObj.downloadedBytes = totalBytesWritten
            downloadTaskObj.totalBytes = totalBytesExpectedToWrite
            downloadTaskObj.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = findDownloadTask(for: task) else { return }

        if let error = error {
            print("❌ ダウンロードエラー: \(error.localizedDescription)")
            DispatchQueue.main.async {
                downloadTask.status = .failed
                downloadTask.error = error
            }
        }
    }
}

// DownloadService拡張（publicメソッド追加用）
extension DownloadService {
    func getDownloadsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let downloadDir = documentsDirectory.appendingPathComponent("Downloads", isDirectory: true)

        if !FileManager.default.fileExists(atPath: downloadDir.path) {
            try? FileManager.default.createDirectory(at: downloadDir, withIntermediateDirectories: true)
        }

        return downloadDir
    }

    func saveToDatabase(fileName: String, filePath: String, fileSize: Int64, folder: String) {
        let downloadedFile = DownloadedFile(context: PersistenceController.shared.container.viewContext)
        downloadedFile.id = UUID()
        downloadedFile.fileName = fileName
        // 絶対パスを相対パスに変換して保存
        downloadedFile.filePath = DownloadService.shared.getRelativePath(from: filePath)
        downloadedFile.fileSize = fileSize
        downloadedFile.downloadedAt = Date()
        downloadedFile.folder = folder

        print("💾 DownloadManager保存: 絶対=\(filePath)")
        print("💾 DownloadManager保存: 相対=\(downloadedFile.filePath ?? "nil")")

        do {
            try PersistenceController.shared.container.viewContext.save()
            print("✅ Core Dataに保存成功")
        } catch {
            print("❌ Core Data保存エラー: \(error)")
        }
    }
}
