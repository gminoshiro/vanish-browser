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
        downloadTask.task?.cancel()

        DispatchQueue.main.async {
            downloadTask.status = .cancelled
            if let index = self.activeDownloads.firstIndex(where: { $0.id == downloadTask.id }) {
                self.activeDownloads.remove(at: index)
            }
            print("❌ ダウンロードキャンセル: \(downloadTask.fileName)")
        }
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
            let destinationURL: URL

            if downloadTaskObj.folder.isEmpty {
                // フォルダ未選択：Downloadsディレクトリ直下に保存
                destinationURL = baseURL.appendingPathComponent(fileName)
            } else {
                // フォルダ指定あり
                let folderURL = baseURL.appendingPathComponent(downloadTaskObj.folder, isDirectory: true)
                if !FileManager.default.fileExists(atPath: folderURL.path) {
                    try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
                }
                destinationURL = folderURL.appendingPathComponent(fileName)
            }
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
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
