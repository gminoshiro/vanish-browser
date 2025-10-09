//
//  DownloadListView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI
import QuickLook

struct DownloadListView: View {
    @Environment(\.dismiss) var dismiss
    @State private var downloads: [DownloadedFile] = []
    @State private var selectedFileURL: URL?

    var body: some View {
        NavigationView {
            List {
                if downloads.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("ダウンロードしたファイルはありません")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(downloads, id: \.id) { download in
                        Button(action: {
                            openFile(download)
                        }) {
                            HStack {
                                // ファイルアイコン
                                Image(systemName: fileIcon(for: download.mimeType))
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(download.fileName ?? "無題")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    HStack {
                                        Text(DownloadService.shared.formatFileSize(download.fileSize))
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if let date = download.downloadedAt {
                                            Text("・")
                                                .foregroundColor(.secondary)
                                            Text(date, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteFiles)
                }
            }
            .navigationTitle("ダウンロード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                if !downloads.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            .onAppear {
                loadDownloads()
            }
            .quickLookPreview($selectedFileURL)
        }
    }

    private func loadDownloads() {
        downloads = DownloadService.shared.fetchDownloadedFiles()
    }

    private func deleteFiles(at offsets: IndexSet) {
        for index in offsets {
            DownloadService.shared.deleteFile(downloads[index])
        }
        loadDownloads()
    }

    private func openFile(_ download: DownloadedFile) {
        guard let filePath = download.filePath else { return }
        selectedFileURL = URL(fileURLWithPath: filePath)
    }

    private func fileIcon(for mimeType: String?) -> String {
        guard let mimeType = mimeType else { return "doc" }

        if mimeType.hasPrefix("image/") {
            return "photo"
        } else if mimeType.hasPrefix("video/") {
            return "film"
        } else if mimeType.hasPrefix("audio/") {
            return "music.note"
        } else if mimeType.contains("pdf") {
            return "doc.text"
        } else if mimeType.contains("zip") || mimeType.contains("archive") {
            return "doc.zipper"
        } else {
            return "doc"
        }
    }
}

#Preview {
    DownloadListView()
}
