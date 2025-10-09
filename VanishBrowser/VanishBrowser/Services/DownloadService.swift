//
//  DownloadService.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import Foundation
import CoreData

class DownloadService {
    static let shared = DownloadService()

    private let viewContext = PersistenceController.shared.container.viewContext
    private let fileManager = FileManager.default

    private init() {}

    // ダウンロードディレクトリのパス
    private var downloadsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let downloadDir = documentsDirectory.appendingPathComponent("Downloads", isDirectory: true)

        // ディレクトリが存在しない場合は作成
        if !fileManager.fileExists(atPath: downloadDir.path) {
            try? fileManager.createDirectory(at: downloadDir, withIntermediateDirectories: true)
        }

        return downloadDir
    }

    // ファイルをダウンロードして保存
    func downloadFile(from url: URL, fileName: String, completion: @escaping (Bool) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self,
                  let tempURL = tempURL,
                  error == nil else {
                print("ダウンロードエラー: \(error?.localizedDescription ?? "Unknown")")
                completion(false)
                return
            }

            // ファイルを保存
            let destinationURL = self.downloadsDirectory.appendingPathComponent(fileName)

            do {
                // 既存ファイルがあれば削除
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    try self.fileManager.removeItem(at: destinationURL)
                }

                // ファイルをコピー
                try self.fileManager.copyItem(at: tempURL, to: destinationURL)

                // Core Dataに保存
                let fileSize = try self.fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Int64 ?? 0
                let mimeType = response?.mimeType

                self.saveDownloadedFile(
                    fileName: fileName,
                    filePath: destinationURL.path,
                    fileSize: fileSize,
                    mimeType: mimeType
                )

                print("ダウンロード完了: \(fileName)")
                completion(true)
            } catch {
                print("ファイル保存エラー: \(error)")
                completion(false)
            }
        }
        task.resume()
    }

    // Core Dataに保存
    private func saveDownloadedFile(fileName: String, filePath: String, fileSize: Int64, mimeType: String?) {
        let downloadedFile = DownloadedFile(context: viewContext)
        downloadedFile.id = UUID()
        downloadedFile.fileName = fileName
        downloadedFile.filePath = filePath
        downloadedFile.fileSize = fileSize
        downloadedFile.mimeType = mimeType
        downloadedFile.downloadedAt = Date()
        downloadedFile.isEncrypted = false // 暗号化は後で実装

        do {
            try viewContext.save()
        } catch {
            print("Core Data保存エラー: \(error)")
        }
    }

    // ダウンロード済みファイル一覧取得
    func fetchDownloadedFiles() -> [DownloadedFile] {
        let request: NSFetchRequest<DownloadedFile> = DownloadedFile.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DownloadedFile.downloadedAt, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("ファイル取得エラー: \(error)")
            return []
        }
    }

    // ファイル削除
    func deleteFile(_ downloadedFile: DownloadedFile) {
        // ファイルシステムから削除
        if let filePath = downloadedFile.filePath {
            try? fileManager.removeItem(atPath: filePath)
        }

        // Core Dataから削除
        viewContext.delete(downloadedFile)

        do {
            try viewContext.save()
            print("ファイルを削除しました")
        } catch {
            print("ファイル削除エラー: \(error)")
        }
    }

    // ファイルサイズをフォーマット
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
