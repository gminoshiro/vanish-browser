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
    @State private var selectedFile: DownloadedFile?
    @State private var showFileViewer = false

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
                    // フォルダ構成表示
                    DownloadFolderSection(title: "動画", icon: "film", files: videoFiles, onSelect: { file in
                        selectedFile = file
                        showFileViewer = true
                    })
                    DownloadFolderSection(title: "画像", icon: "photo", files: imageFiles, onSelect: { file in
                        selectedFile = file
                        showFileViewer = true
                    })
                    DownloadFolderSection(title: "音楽", icon: "music.note", files: audioFiles, onSelect: { file in
                        selectedFile = file
                        showFileViewer = true
                    })
                    DownloadFolderSection(title: "書類", icon: "doc.text", files: documentFiles, onSelect: { file in
                        selectedFile = file
                        showFileViewer = true
                    })
                    DownloadFolderSection(title: "その他", icon: "doc", files: otherFiles, onSelect: { file in
                        selectedFile = file
                        showFileViewer = true
                    })
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
            }
            .onAppear {
                loadDownloads()
            }
            .sheet(isPresented: $showFileViewer) {
                if let file = selectedFile {
                    FileViewerView(file: file)
                }
            }
        }
    }

    private var videoFiles: [DownloadedFile] {
        downloads.filter { isVideoFile($0.mimeType) || hasVideoExtension($0.fileName) }
    }

    private var imageFiles: [DownloadedFile] {
        downloads.filter { isImageFile($0.mimeType) || hasImageExtension($0.fileName) }
    }

    private var audioFiles: [DownloadedFile] {
        downloads.filter { isAudioFile($0.mimeType) || hasAudioExtension($0.fileName) }
    }

    private var documentFiles: [DownloadedFile] {
        downloads.filter { isDocumentFile($0.mimeType) || hasDocumentExtension($0.fileName) }
    }

    private var otherFiles: [DownloadedFile] {
        downloads.filter { file in
            !videoFiles.contains(where: { $0.id == file.id }) &&
            !imageFiles.contains(where: { $0.id == file.id }) &&
            !audioFiles.contains(where: { $0.id == file.id }) &&
            !documentFiles.contains(where: { $0.id == file.id })
        }
    }

    private func loadDownloads() {
        downloads = DownloadService.shared.fetchDownloadedFiles()
    }

    private func isVideoFile(_ mimeType: String?) -> Bool {
        guard let mimeType = mimeType else { return false }
        return mimeType.hasPrefix("video/")
    }

    private func isImageFile(_ mimeType: String?) -> Bool {
        guard let mimeType = mimeType else { return false }
        return mimeType.hasPrefix("image/")
    }

    private func isAudioFile(_ mimeType: String?) -> Bool {
        guard let mimeType = mimeType else { return false }
        return mimeType.hasPrefix("audio/")
    }

    private func isDocumentFile(_ mimeType: String?) -> Bool {
        guard let mimeType = mimeType else { return false }
        return mimeType.contains("pdf") || mimeType.contains("document")
    }

    private func hasVideoExtension(_ fileName: String?) -> Bool {
        guard let fileName = fileName else { return false }
        let ext = (fileName as NSString).pathExtension.lowercased()
        return ["mp4", "mov", "avi", "mkv", "webm"].contains(ext)
    }

    private func hasImageExtension(_ fileName: String?) -> Bool {
        guard let fileName = fileName else { return false }
        let ext = (fileName as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "webp"].contains(ext)
    }

    private func hasAudioExtension(_ fileName: String?) -> Bool {
        guard let fileName = fileName else { return false }
        let ext = (fileName as NSString).pathExtension.lowercased()
        return ["mp3", "wav", "m4a", "flac"].contains(ext)
    }

    private func hasDocumentExtension(_ fileName: String?) -> Bool {
        guard let fileName = fileName else { return false }
        let ext = (fileName as NSString).pathExtension.lowercased()
        return ["pdf", "doc", "docx", "txt"].contains(ext)
    }
}

// フォルダセクション
struct DownloadFolderSection: View {
    let title: String
    let icon: String
    let files: [DownloadedFile]
    let onSelect: (DownloadedFile) -> Void

    var body: some View {
        if !files.isEmpty {
            Section(header: HStack {
                Image(systemName: icon)
                Text(title)
            }) {
                ForEach(files, id: \.id) { download in
                    Button(action: {
                        onSelect(download)
                    }) {
                        HStack {
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
                .onDelete { offsets in
                    for index in offsets {
                        DownloadService.shared.deleteFile(files[index])
                    }
                }
            }
        }
    }
}

#Preview {
    DownloadListView()
}
