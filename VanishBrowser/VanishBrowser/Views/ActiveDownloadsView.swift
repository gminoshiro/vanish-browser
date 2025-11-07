//
//  ActiveDownloadsView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/11.
//

import SwiftUI
import Combine

struct ActiveDownloadsView: View {
    @ObservedObject var downloadManager = DownloadManager.shared

    var body: some View {
        VStack(spacing: 0) {
            if downloadManager.activeDownloads.isEmpty {
                Text("ダウンロード中のファイルはありません")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(downloadManager.activeDownloads) { download in
                        DownloadTaskRow(downloadTask: download)
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("downloads.active", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DownloadTaskRow: View {
    @ObservedObject var downloadTask: DownloadTask
    @ObservedObject var downloadManager = DownloadManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ファイル名
            Text(downloadTask.fileName)
                .font(.headline)
                .lineLimit(1)

            // フォルダ
            Text("保存先: \(downloadTask.folder)")
                .font(.caption)
                .foregroundColor(.secondary)

            // プログレスバー
            if downloadTask.status == .downloading || downloadTask.status == .paused {
                ProgressView(value: downloadTask.progress)
                    .progressViewStyle(LinearProgressViewStyle())

                HStack {
                    Text(downloadTask.progressText)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(downloadTask.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // ステータス
            HStack {
                Text(downloadTask.statusText)
                    .font(.caption)
                    .foregroundColor(statusColor(for: downloadTask.status))

                Spacer()

                // コントロールボタン
                HStack(spacing: 12) {
                    if downloadTask.status == .downloading {
                        Button(action: {
                            downloadManager.pauseDownload(downloadTask)
                        }) {
                            Image(systemName: "pause.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    } else if downloadTask.status == .paused {
                        Button(action: {
                            downloadManager.resumeDownload(downloadTask)
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }

                    if downloadTask.status == .downloading || downloadTask.status == .paused {
                        Button(action: {
                            downloadManager.cancelDownload(downloadTask)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statusColor(for status: DownloadStatus) -> Color {
        switch status {
        case .pending:
            return .gray
        case .downloading:
            return .blue
        case .paused:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
}
