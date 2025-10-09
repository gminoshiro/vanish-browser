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

    // ファイルをダウンロードして保存（フォルダ自動振り分け）
    func downloadFile(from url: URL, fileName: String, completion: @escaping (Bool) -> Void) {
        print("📥 ダウンロード開始: \(fileName)")

        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            if let error = error {
                print("❌ ダウンロードエラー: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }

            guard let tempURL = tempURL else {
                print("❌ 一時ファイルが見つかりません")
                DispatchQueue.main.async { completion(false) }
                return
            }

            // ファイルタイプに応じてフォルダを振り分け
            let folder = self.detectFileType(fileName: fileName, mimeType: response?.mimeType)
            let categoryDir = self.downloadsDirectory.appendingPathComponent(folder, isDirectory: true)

            do {
                // カテゴリフォルダが存在しない場合は作成
                if !self.fileManager.fileExists(atPath: categoryDir.path) {
                    try self.fileManager.createDirectory(at: categoryDir, withIntermediateDirectories: true)
                    print("📁 フォルダ作成: \(folder)")
                }

                let destinationURL = categoryDir.appendingPathComponent(fileName)

                // 既存ファイルがあれば削除
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    try self.fileManager.removeItem(at: destinationURL)
                }

                // ファイルをコピー
                try self.fileManager.copyItem(at: tempURL, to: destinationURL)
                print("✅ ファイル保存成功: \(destinationURL.path)")

                // Core Dataに保存 - メインスレッドで実行
                let fileSize = try self.fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Int64 ?? 0
                let mimeType = response?.mimeType

                DispatchQueue.main.async {
                    // 少し遅延を入れてスレッド競合を回避
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.saveDownloadedFile(
                            fileName: fileName,
                            filePath: destinationURL.path,
                            fileSize: fileSize,
                            mimeType: mimeType,
                            folder: folder
                        )
                        completion(true)
                    }
                }
            } catch {
                print("❌ ファイル保存エラー: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
            }
        }
        task.resume()
    }

    // ファイルタイプを検出してフォルダ名を返す
    private func detectFileType(fileName: String, mimeType: String?) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()

        if ["jpg", "jpeg", "png", "gif", "webp", "bmp", "svg"].contains(ext) {
            return "画像"
        } else if ["mp4", "mov", "avi", "mkv", "webm", "flv"].contains(ext) {
            return "動画"
        } else if ["mp3", "wav", "m4a", "flac", "aac", "ogg"].contains(ext) {
            return "音楽"
        } else if ["pdf", "doc", "docx", "txt", "rtf", "pages"].contains(ext) {
            return "書類"
        } else if ["zip", "rar", "7z", "tar", "gz"].contains(ext) {
            return "アーカイブ"
        }

        return "その他"
    }

    // Core Dataに保存
    private func saveDownloadedFile(fileName: String, filePath: String, fileSize: Int64, mimeType: String?, folder: String) {
        // メインスレッドで実行されていることを確認（デバッグのみ）
        #if DEBUG
        assert(Thread.isMainThread, "saveDownloadedFile must be called on main thread")
        #endif

        // メインスレッドでない場合は強制的にメインスレッドで実行
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.saveDownloadedFile(
                    fileName: fileName,
                    filePath: filePath,
                    fileSize: fileSize,
                    mimeType: mimeType,
                    folder: folder
                )
            }
            return
        }

        do {
            let downloadedFile = DownloadedFile(context: viewContext)
            downloadedFile.id = UUID()
            downloadedFile.fileName = fileName
            downloadedFile.filePath = filePath
            downloadedFile.fileSize = fileSize
            downloadedFile.mimeType = mimeType
            downloadedFile.downloadedAt = Date()
            downloadedFile.isEncrypted = false // 暗号化は後で実装

            // Core Dataに変更があるか確認して保存
            if viewContext.hasChanges {
                try viewContext.save()
                print("💾 Core Data保存成功: \(fileName) → \(folder)")
            } else {
                print("⚠️ Core Dataに変更がありません")
            }
        } catch let error as NSError {
            print("❌ Core Data保存エラー: \(error.localizedDescription)")
            print("❌ 詳細: \(error)")
            print("❌ UserInfo: \(error.userInfo)")

            // ロールバックして状態をリセット
            viewContext.rollback()
            print("⚙️ Core Dataロールバック実行")
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
