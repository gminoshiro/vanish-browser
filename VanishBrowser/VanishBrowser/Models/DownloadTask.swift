//
//  DownloadTask.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/11.
//

import Foundation
import Combine

enum DownloadStatus {
    case pending
    case downloading
    case paused
    case completed
    case failed
    case cancelled
}

class DownloadTask: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    let folder: String

    @Published var status: DownloadStatus = .pending
    @Published var progress: Float = 0.0
    @Published var downloadedBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var error: Error?

    var task: URLSessionDownloadTask?
    var resumeData: Data?

    init(url: URL, fileName: String, folder: String) {
        self.url = url
        self.fileName = fileName
        self.folder = folder
    }

    var progressText: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file

        if totalBytes > 0 {
            let downloaded = formatter.string(fromByteCount: downloadedBytes)
            let total = formatter.string(fromByteCount: totalBytes)
            return "\(downloaded) / \(total)"
        } else {
            return formatter.string(fromByteCount: downloadedBytes)
        }
    }

    var statusText: String {
        switch status {
        case .pending:
            return "待機中"
        case .downloading:
            return "ダウンロード中"
        case .paused:
            return "一時停止"
        case .completed:
            return "完了"
        case .failed:
            return "失敗"
        case .cancelled:
            return "キャンセル"
        }
    }
}
