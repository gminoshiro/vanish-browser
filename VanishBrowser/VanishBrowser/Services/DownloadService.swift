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
    var activeDownloads: [URLSessionTask: String] = [:] // taskとfileNameのマッピング（delegate用にinternal）

    private init() {
        // 起動時に既存の絶対パスを相対パスに変換
        migrateAbsolutePathsToRelative()
        // 起動時に使用されていないデフォルトフォルダを削除
        removeUnusedDefaultFolders()
    }

    // 使用されていないデフォルトフォルダのみを削除する
    private func removeUnusedDefaultFolders() {
        let defaultFolders = ["メディア", "動画", "画像", "書類", "アーカイブ", "その他"]
        let request: NSFetchRequest<DownloadedFile> = DownloadedFile.fetchRequest()

        do {
            let files = try viewContext.fetch(request)

            // 実際に使用されているフォルダを取得
            let usedFolders = Set(files.compactMap { $0.folder })

            // デフォルトフォルダのうち、使用されていないものだけ削除
            for folderName in defaultFolders {
                // フォルダが使用されている場合はスキップ
                if usedFolders.contains(folderName) {
                    continue
                }

                let folderPath = downloadsDirectory.appendingPathComponent(folderName)
                if fileManager.fileExists(atPath: folderPath.path) {
                    // フォルダ内にファイルがないか確認
                    let contents = try? fileManager.contentsOfDirectory(atPath: folderPath.path)
                    if contents?.isEmpty ?? true {
                        try? fileManager.removeItem(at: folderPath)
                        print("🗑️ 未使用のデフォルトフォルダ削除: \(folderName)")
                    }
                }
            }
        } catch {
            print("❌ デフォルトフォルダ削除エラー: \(error)")
        }
    }

    // 既存の絶対パスを相対パスに変換（マイグレーション）
    private func migrateAbsolutePathsToRelative() {
        let request: NSFetchRequest<DownloadedFile> = DownloadedFile.fetchRequest()

        do {
            let files = try viewContext.fetch(request)
            var migratedCount = 0
            var folderFixCount = 0

            for file in files {
                // パス変換
                if let filePath = file.filePath {
                    // 絶対パスかどうか判定（"/"で始まるか、Documentsを含む）
                    if filePath.hasPrefix("/") || filePath.contains("Documents") {
                        // 相対パスに変換
                        let relativePath = getRelativePath(from: filePath)
                        if relativePath != filePath {
                            file.filePath = relativePath
                            migratedCount += 1
                            print("🔄 パス変換: \(filePath) -> \(relativePath)")
                        }
                    }
                }

                // folder が nil の場合、パスから推測
                if file.folder == nil, let filePath = file.filePath {
                    // パスから "Downloads/フォルダ名/ファイル名" のフォルダ名部分を取得
                    let components = filePath.components(separatedBy: "/")
                    if components.count >= 3 && components[0] == "Downloads" {
                        let folderName = components[1]
                        file.folder = folderName
                        folderFixCount += 1
                        print("📁 フォルダ補完: \(file.fileName ?? "不明") -> \(folderName)")
                    }
                }
            }

            if migratedCount > 0 || folderFixCount > 0 {
                try viewContext.save()
                if migratedCount > 0 {
                    print("✅ \(migratedCount)個のファイルパスを相対パスに変換しました")
                }
                if folderFixCount > 0 {
                    print("✅ \(folderFixCount)個のファイルのフォルダを補完しました")
                }
            }
        } catch {
            print("❌ パスマイグレーションエラー: \(error)")
        }
    }

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

    // ファイルタイプを検出してフォルダ名を返す
    private func detectFileType(fileName: String, mimeType: String?) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()

        if ["jpg", "jpeg", "png", "gif", "webp", "bmp", "svg"].contains(ext) {
            return "メディア"
        } else if ["mp4", "mov", "avi", "mkv", "webm", "flv"].contains(ext) {
            return "メディア"
        } else if ["mp3", "wav", "m4a", "flac", "aac", "ogg"].contains(ext) {
            return "メディア"
        } else if ["pdf", "doc", "docx", "txt", "rtf", "pages"].contains(ext) {
            return "書類"
        } else if ["zip", "rar", "7z", "tar", "gz"].contains(ext) {
            return "アーカイブ"
        }

        return "その他"
    }

    // 相対パスに変換（Documents以降のパスを取得）
    func getRelativePath(from absolutePath: String) -> String {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        if absolutePath.hasPrefix(documentsPath) {
            let relativePath = String(absolutePath.dropFirst(documentsPath.count))
            // 先頭のスラッシュを除去
            return relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        }
        return absolutePath // フォールバック：変換できない場合は元のパスを返す
    }

    // 相対パスから絶対パスを復元
    func getAbsolutePath(from relativePath: String) -> String {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        let absolutePath = documentsPath + "/" + relativePath
        print("🔍 getAbsolutePath: \(relativePath) -> \(absolutePath)")
        print("🔍 ファイル存在: \(fileManager.fileExists(atPath: absolutePath))")
        return absolutePath
    }

    // Core Dataに保存
    func saveDownloadedFile(fileName: String, filePath: String, fileSize: Int64, mimeType: String?, folder: String?) {
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
            // 絶対パスを相対パスに変換して保存
            downloadedFile.filePath = getRelativePath(from: filePath)
            downloadedFile.fileSize = fileSize
            downloadedFile.mimeType = mimeType
            downloadedFile.downloadedAt = Date()
            downloadedFile.isEncrypted = false // 暗号化は後で実装
            downloadedFile.folder = folder // フォルダ名を設定

            print("💾 保存パス: 絶対=\(filePath)")
            print("💾 保存パス: 相対=\(downloadedFile.filePath ?? "nil")")

            // Core Dataに変更があるか確認して保存
            if viewContext.hasChanges {
                try viewContext.save()
                print("💾 Core Data保存成功: \(fileName) → \(folder ?? "ホーム")")
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
            let files = try viewContext.fetch(request)
            // デフォルトフォルダの自動割り当てを削除（ユーザーが明示的に選択したフォルダのみ使用）
            return files
        } catch {
            print("ファイル取得エラー: \(error)")
            return []
        }
    }

    // ファイル削除
    func deleteFile(_ downloadedFile: DownloadedFile) {
        // ファイルシステムから削除
        if let relativePath = downloadedFile.filePath {
            let absolutePath = getAbsolutePath(from: relativePath)
            try? fileManager.removeItem(atPath: absolutePath)
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

    // 空のフォルダを削除
    func removeEmptyFolders() {
        do {
            let downloadsDirURL = downloadsDirectory
            let contents = try fileManager.contentsOfDirectory(at: downloadsDirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])

            for folderURL in contents {
                // ディレクトリかどうかチェック
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                    continue
                }

                // フォルダ内のファイル数をチェック
                let folderContents = try fileManager.contentsOfDirectory(atPath: folderURL.path)
                if folderContents.isEmpty {
                    try fileManager.removeItem(at: folderURL)
                    print("🗑️ 空のフォルダを削除: \(folderURL.lastPathComponent)")
                }
            }
        } catch {
            print("❌ 空フォルダ削除エラー: \(error)")
        }
    }

    // すべてのフォルダを強制削除（一時フォルダを含む）
    func removeAllFolders() {
        do {
            let downloadsDirURL = downloadsDirectory
            let contents = try fileManager.contentsOfDirectory(at: downloadsDirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])

            for folderURL in contents {
                // ディレクトリかどうかチェック
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                    continue
                }

                // フォルダを削除（空でなくても削除）
                try fileManager.removeItem(at: folderURL)
                print("🗑️ フォルダを削除: \(folderURL.lastPathComponent)")
            }
            print("✅ すべてのフォルダを削除しました")
        } catch {
            print("❌ フォルダ削除エラー: \(error)")
        }
    }

    // ファイルサイズをフォーマット
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // フォルダ作成
    func createFolder(name: String) -> Bool {
        let folderURL = downloadsDirectory.appendingPathComponent(name, isDirectory: true)

        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            print("📁 フォルダ作成成功: \(name)")
            return true
        } catch {
            print("❌ フォルダ作成エラー: \(error)")
            return false
        }
    }

    // フォルダ名変更
    func renameFolder(from oldName: String, to newName: String) -> Bool {
        let oldFolderURL = downloadsDirectory.appendingPathComponent(oldName, isDirectory: true)
        let newFolderURL = downloadsDirectory.appendingPathComponent(newName, isDirectory: true)

        do {
            // ファイルシステムでフォルダをリネーム
            if fileManager.fileExists(atPath: oldFolderURL.path) {
                try fileManager.moveItem(at: oldFolderURL, to: newFolderURL)
            }

            // Core Data内のファイルのフォルダ名を更新
            let request: NSFetchRequest<DownloadedFile> = DownloadedFile.fetchRequest()
            request.predicate = NSPredicate(format: "folder == %@", oldName)

            let filesInFolder = try viewContext.fetch(request)
            for file in filesInFolder {
                file.folder = newName
            }

            try viewContext.save()
            print("📁 フォルダ名変更成功: \(oldName) → \(newName)")
            return true
        } catch {
            print("❌ フォルダ名変更エラー: \(error)")
            return false
        }
    }

    // フォルダ削除（フォルダ内の全ファイルとCore Dataも削除）
    func deleteFolder(name: String) -> Bool {
        let folderURL = downloadsDirectory.appendingPathComponent(name, isDirectory: true)

        do {
            // フォルダ内のファイルを取得してCore Dataから削除
            let request: NSFetchRequest<DownloadedFile> = DownloadedFile.fetchRequest()
            request.predicate = NSPredicate(format: "folder == %@", name)

            let filesInFolder = try viewContext.fetch(request)
            for file in filesInFolder {
                viewContext.delete(file)
            }

            // Core Dataを保存
            try viewContext.save()

            // ファイルシステムからフォルダを削除
            if fileManager.fileExists(atPath: folderURL.path) {
                try fileManager.removeItem(at: folderURL)
                print("📁 フォルダ削除成功: \(name)")
            }

            return true
        } catch {
            print("❌ フォルダ削除エラー: \(error)")
            return false
        }
    }

    // ストレージ使用量を計算
    func calculateStorageUsage() -> (totalBytes: Int64, fileCount: Int) {
        let files = fetchDownloadedFiles()
        let totalBytes = files.reduce(0) { $0 + $1.fileSize }
        return (totalBytes, files.count)
    }

    // デバイスの空き容量を取得
    func getAvailableStorage() -> Int64? {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return nil
        }

        do {
            let systemAttributes = try fileManager.attributesOfFileSystem(forPath: path)
            if let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                return freeSpace.int64Value
            }
        } catch {
            print("❌ 空き容量取得エラー: \(error)")
        }

        return nil
    }

    // ファイルをリネーム
    func renameFile(_ file: DownloadedFile, newName: String) -> Bool {
        guard let relativePath = file.filePath else { return false }

        let oldAbsolutePath = getAbsolutePath(from: relativePath)
        let oldURL = URL(fileURLWithPath: oldAbsolutePath)
        let parentURL = oldURL.deletingLastPathComponent()
        let newURL = parentURL.appendingPathComponent(newName)

        do {
            try fileManager.moveItem(at: oldURL, to: newURL)

            // Core Dataを更新（相対パスに変換して保存）
            file.fileName = newName
            file.filePath = getRelativePath(from: newURL.path)
            try viewContext.save()

            print("✏️ リネーム成功: \(relativePath) -> \(file.filePath ?? "nil")")
            return true
        } catch {
            print("❌ リネームエラー: \(error)")
            return false
        }
    }

    // ファイルを別フォルダに移動
    func moveFile(_ file: DownloadedFile, toFolder folderName: String) -> Bool {
        guard let relativePath = file.filePath else { return false }

        let oldAbsolutePath = getAbsolutePath(from: relativePath)
        let oldURL = URL(fileURLWithPath: oldAbsolutePath)
        let fileName = oldURL.lastPathComponent
        let newFolderURL = downloadsDirectory.appendingPathComponent(folderName, isDirectory: true)

        // フォルダが存在しない場合は作成
        if !fileManager.fileExists(atPath: newFolderURL.path) {
            do {
                try fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: true)
            } catch {
                print("❌ フォルダ作成エラー: \(error)")
                return false
            }
        }

        let newURL = newFolderURL.appendingPathComponent(fileName)

        do {
            try fileManager.moveItem(at: oldURL, to: newURL)

            // Core Dataを更新（相対パスに変換して保存）
            file.filePath = getRelativePath(from: newURL.path)
            try viewContext.save()

            print("📦 移動成功: \(relativePath) -> \(file.filePath ?? "nil")")
            return true
        } catch {
            print("❌ 移動エラー: \(error)")
            return false
        }
    }

    // ダウンロードフォルダ内の全フォルダ取得
    func getAllFolders() -> [String] {
        do {
            let contents = try fileManager.contentsOfDirectory(at: downloadsDirectory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])

            let folders = contents.filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            }.map { $0.lastPathComponent }

            return folders.sorted()
        } catch {
            print("❌ フォルダ一覧取得エラー: \(error)")
            return []
        }
    }

    // ファイルをダウンロードして保存（フォルダ指定可能）
    func downloadFile(from url: URL, fileName: String, toFolder folder: String? = nil, completion: @escaping (Bool) -> Void) {
        print("📥 ダウンロード開始: \(fileName)")

        let session = URLSession(configuration: .default, delegate: DownloadDelegate.shared, delegateQueue: nil)
        var taskRef: URLSessionDownloadTask?
        let task = session.downloadTask(with: url) { [weak self] tempURL, response, error in
            defer {
                // ダウンロード完了時にアクティブリストから削除
                if let task = taskRef {
                    self?.activeDownloads.removeValue(forKey: task)
                }
            }

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

            // フォルダが指定されていればそれを使用、空文字列の場合はホーム（フォルダなし）
            let targetFolder = folder?.isEmpty == true ? nil : folder
            let categoryDir: URL

            if let folder = targetFolder, !folder.isEmpty {
                // フォルダ指定あり
                categoryDir = self.downloadsDirectory.appendingPathComponent(folder, isDirectory: true)
            } else {
                // ホーム（Downloadsディレクトリ直下）
                categoryDir = self.downloadsDirectory
            }

            do {
                // カテゴリフォルダが存在しない場合は作成（ホーム以外）
                if let folder = targetFolder, !folder.isEmpty {
                    if !self.fileManager.fileExists(atPath: categoryDir.path) {
                        try self.fileManager.createDirectory(at: categoryDir, withIntermediateDirectories: true)
                        print("📁 フォルダ作成: \(folder)")
                    }
                }

                let destinationURL = categoryDir.appendingPathComponent(fileName)

                // 既存ファイルがあれば削除
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    try self.fileManager.removeItem(at: destinationURL)
                }

                // ファイルをコピー
                try self.fileManager.copyItem(at: tempURL, to: destinationURL)
                print("✅ ファイル保存成功: \(destinationURL.path)")

                // Core Dataに保存
                let fileSize = try self.fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Int64 ?? 0
                let mimeType = response?.mimeType

                DispatchQueue.main.async {
                    self.saveDownloadedFile(
                        fileName: fileName,
                        filePath: destinationURL.path,
                        fileSize: fileSize,
                        mimeType: mimeType,
                        folder: targetFolder
                    )

                    // ダウンロード完了通知を送信
                    NotificationCenter.default.post(
                        name: NSNotification.Name("DownloadCompleted"),
                        object: nil,
                        userInfo: [
                            "fileName": fileName,
                            "fileSize": fileSize,
                            "isVideo": mimeType?.contains("video") ?? false
                        ]
                    )

                    completion(true)
                }
            } catch {
                print("❌ ファイル保存エラー: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
            }
        }

        // タスクとファイル名を紐付け
        taskRef = task
        activeDownloads[task] = fileName
        task.resume()
    }

    // 後方互換性のための従来のdownloadFile関数
    func downloadFile(from url: URL, fileName: String, completion: @escaping (Bool) -> Void) {
        downloadFile(from: url, fileName: fileName, toFolder: nil, completion: completion)
    }

    // 旧: ファイルをダウンロードして保存（プログレス付き）
    func _old_downloadFile(from url: URL, fileName: String, completion: @escaping (Bool) -> Void) {
        print("📥 ダウンロード開始: \(fileName)")

        let session = URLSession(configuration: .default, delegate: DownloadDelegate.shared, delegateQueue: nil)
        let task = session.downloadTask(with: url) { [weak self] tempURL, response, error in
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

                // Core Dataに保存
                let fileSize = try self.fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Int64 ?? 0
                let mimeType = response?.mimeType

                DispatchQueue.main.async {
                    self.saveDownloadedFile(
                        fileName: fileName,
                        filePath: destinationURL.path,
                        fileSize: fileSize,
                        mimeType: mimeType,
                        folder: folder
                    )
                    completion(true)
                }
            } catch {
                print("❌ ファイル保存エラー: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
            }
        }
        task.resume()
    }
}

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    static let shared = DownloadDelegate()

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let fileName = DownloadService.shared.activeDownloads[downloadTask]

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("DownloadProgress"),
                object: progress,
                userInfo: fileName != nil ? ["fileName": fileName!] : nil
            )
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 完了処理はdownloadTaskのcompletionで行う
    }
}
