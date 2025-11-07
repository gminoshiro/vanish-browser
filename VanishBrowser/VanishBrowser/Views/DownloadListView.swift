//
//  DownloadListView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI
import QuickLook
import AVFoundation
import Combine

enum SortOption: String, CaseIterable {
    case name = "name"
    case date = "date"
    case size = "size"

    var displayText: String {
        switch self {
        case .name:
            return NSLocalizedString("downloads.sort.name", comment: "")
        case .date:
            return NSLocalizedString("downloads.sort.date", comment: "")
        case .size:
            return NSLocalizedString("downloads.sort.size", comment: "")
        }
    }
}

struct DownloadListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = DownloadListViewModel()
    @State private var downloads: [DownloadedFile] = []
    @State private var folders: [String] = []
    @State private var selectedFile: DownloadedFile?
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    @State private var showRenameFile = false
    @State private var newFileName = ""
    @State private var showMoveFile = false
    @State private var selectedFolder = ""
    @State private var showFolderPicker = false  // フォルダ選択ダイアログ
    @State private var showDeleteFolder = false
    @State private var folderToDelete = ""
    @State private var sortOption: SortOption = .date
    @State private var showRenameFolder = false
    @State private var newFolderRename = ""
    @State private var folderToRename = ""
    @State private var searchText = ""
    @State private var selectedFolderForView: String? = nil // フォルダ内部表示用
    @State private var downloadProgress: Float = 0.0
    @State private var isDownloading = false
    @State private var downloadingFileName = ""
    @State private var selectedVideoFile: DownloadedFile?  // 選択された動画ファイル

    var filteredDownloads: [DownloadedFile] {
        if searchText.isEmpty {
            return downloads
        }
        return downloads.filter { file in
            file.fileName?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    @ViewBuilder
    var homeFilesSection: some View {
        let homeFiles = filesInFolder("")
        ForEach(Array(homeFiles.enumerated()), id: \.element.id) { index, download in
            fileRow(for: download, allFiles: homeFiles, index: index)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バーとソートメニュー
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("ファイルを検索", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                sortOption = option
                                loadDownloads()
                            }) {
                                HStack {
                                    Text(option.displayText)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortOption.displayText)
                        }
                        .font(.caption)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // ダウンロード進捗バー
                if isDownloading {
                    VStack(spacing: 4) {
                        HStack {
                            Text("ダウンロード中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(downloadProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: downloadProgress, total: 1.0)
                            .progressViewStyle(.linear)
                        Text(downloadingFileName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }

            List {
                // ダウンロード中のファイルセクション
                if !DownloadManager.shared.activeDownloads.isEmpty {
                    Section {
                        NavigationLink(destination: ActiveDownloadsView()) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.blue)
                                Text("ダウンロード中 (\(DownloadManager.shared.activeDownloads.count))")
                                    .font(.headline)
                            }
                        }
                    }
                }

                if selectedFolderForView != nil {
                    // フォルダ内のファイル表示
                    let folderFiles = filesInFolder(selectedFolderForView!)
                    ForEach(Array(folderFiles.enumerated()), id: \.element.id) { index, download in
                        fileRow(for: download, allFiles: folderFiles, index: index)
                    }
                } else if filteredDownloads.isEmpty && folders.isEmpty {
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
                    // フォルダ一覧のみ表示（ファイルは非表示）
                    ForEach(folders, id: \.self) { folder in
                        Button(action: {
                            selectedFolderForView = folder
                        }) {
                            HStack {
                                Image(systemName: folderIcon(folder))
                                    .font(.title2)
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(folder)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("\(filesInFolder(folder).count)個のファイル")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                folderToDelete = folder
                                showDeleteFolder = true
                            } label: {
                                Label("削除", systemImage: "trash")
                            }

                            Button {
                                folderToRename = folder
                                newFolderRename = folder
                                showRenameFolder = true
                            } label: {
                                Label("名前変更", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }

                    // ホームのファイル（フォルダなし）
                    homeFilesSection
                }
            }
            }
            .navigationTitle(selectedFolderForView ?? NSLocalizedString("downloads.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedFolderForView != nil {
                        Button(action: {
                            selectedFolderForView = nil
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("戻る")
                            }
                        }
                    } else {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateFolder = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .onAppear {
                loadDownloads()

                // ダウンロード進捗の監視
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("DownloadProgress"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let progress = notification.object as? Float {
                        downloadProgress = progress
                        isDownloading = progress < 1.0

                        if let userInfo = notification.userInfo,
                           let fileName = userInfo["fileName"] as? String {
                            downloadingFileName = fileName
                        }
                    }
                }

                // ダウンロード完了の監視
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("DownloadCompleted"),
                    object: nil,
                    queue: .main
                ) { notification in
                    isDownloading = false
                    downloadProgress = 0.0
                    downloadingFileName = ""
                    loadDownloads()
                }
            }
            .alert("新規フォルダ", isPresented: $showCreateFolder) {
                TextField("フォルダ名", text: $newFolderName)
                Button("作成") {
                    if !newFolderName.isEmpty {
                        if DownloadService.shared.createFolder(name: newFolderName) {
                            print("✅ フォルダ作成成功: \(newFolderName)")
                            // 空フォルダも表示するために即座にフォルダ一覧を追加
                            if !folders.contains(newFolderName) {
                                folders.append(newFolderName)
                                folders.sort()
                            }
                            // さらに念のため再読み込み
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                loadDownloads()
                            }
                        }
                        newFolderName = ""
                    }
                }
                Button("キャンセル", role: .cancel) {
                    newFolderName = ""
                }
            } message: {
                Text("新しいフォルダ名を入力してください")
            }
            .alert("ファイルをリネーム", isPresented: $showRenameFile) {
                TextField("新しいファイル名", text: Binding(
                    get: {
                        // 拡張子を除いたファイル名のみ表示
                        (newFileName as NSString).deletingPathExtension
                    },
                    set: { newValue in
                        // 拡張子を維持したまま名前だけ変更
                        let ext = (newFileName as NSString).pathExtension
                        newFileName = ext.isEmpty ? newValue : "\(newValue).\(ext)"
                    }
                ))
                Button("変更") {
                    if !newFileName.isEmpty, let file = selectedFile {
                        if DownloadService.shared.renameFile(file, newName: newFileName) {
                            loadDownloads()
                        }
                        newFileName = ""
                    }
                }
                Button("キャンセル", role: .cancel) {
                    newFileName = ""
                }
            } message: {
                let ext = (newFileName as NSString).pathExtension
                if !ext.isEmpty {
                    Text("拡張子 .\(ext) は自動的に保持されます")
                }
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerForMoveView(
                    selectedFolder: $selectedFolder,
                    onSelect: { folder in
                        if let file = selectedFile {
                            if DownloadService.shared.moveFile(file, toFolder: folder) {
                                // 強制的にViewを再描画
                                viewModel.refresh()
                                loadDownloads()
                            }
                        }
                    }
                )
            }
            .alert("フォルダを削除", isPresented: $showDeleteFolder) {
                Button("削除", role: .destructive) {
                    if DownloadService.shared.deleteFolder(name: folderToDelete) {
                        loadDownloads()
                    }
                    folderToDelete = ""
                }
                Button("キャンセル", role: .cancel) {
                    folderToDelete = ""
                }
            } message: {
                Text(String(format: NSLocalizedString("alert.deleteFolderMessage", comment: ""), folderToDelete))
            }
            .alert("フォルダ名を変更", isPresented: $showRenameFolder) {
                TextField("新しいフォルダ名", text: $newFolderRename)
                Button("変更") {
                    if !newFolderRename.isEmpty && folderToRename != newFolderRename {
                        if DownloadService.shared.renameFolder(from: folderToRename, to: newFolderRename) {
                            loadDownloads()
                        }
                    }
                    newFolderRename = ""
                    folderToRename = ""
                }
                Button("キャンセル", role: .cancel) {
                    newFolderRename = ""
                    folderToRename = ""
                }
            }
            .fullScreenCover(item: $selectedVideoFile) { videoFile in
                if let relativePath = videoFile.filePath {
                    let absolutePath = DownloadService.shared.getAbsolutePath(from: relativePath)
                    let videoURL = URL(fileURLWithPath: absolutePath)
                    CustomVideoPlayerView(
                        videoURL: videoURL,
                        videoFileName: videoFile.fileName ?? "無題",
                        showDownloadButton: false,
                        isPresented: Binding(
                            get: { selectedVideoFile != nil },
                            set: { if !$0 { selectedVideoFile = nil } }
                        )
                    )
                }
            }
        }
    }

    private func filesInFolder(_ folderName: String) -> [DownloadedFile] {
        let folderFiles: [DownloadedFile]
        if folderName.isEmpty {
            // ホーム：folderがnilまたは空文字列のファイル
            folderFiles = filteredDownloads.filter { $0.folder == nil || $0.folder?.isEmpty == true }
        } else {
            folderFiles = filteredDownloads.filter { $0.folder == folderName }
        }

        // ソート
        switch sortOption {
        case .name:
            return folderFiles.sorted { ($0.fileName ?? "") < ($1.fileName ?? "") }
        case .date:
            return folderFiles.sorted { ($0.downloadedAt ?? Date.distantPast) > ($1.downloadedAt ?? Date.distantPast) }
        case .size:
            return folderFiles.sorted { $0.fileSize > $1.fileSize }
        }
    }

    private func folderIcon(_ folderName: String) -> String {
        // 全てのフォルダを統一アイコンに
        return "folder.fill"
    }

    private func loadDownloads() {
        downloads = DownloadService.shared.fetchDownloadedFiles()
        loadFolders()
    }

    private func isVideoFile(_ file: DownloadedFile) -> Bool {
        guard let fileName = file.fileName else { return false }
        let ext = (fileName as NSString).pathExtension.lowercased()
        return ["mp4", "mov", "m4v", "avi", "mkv", "webm", "m3u8"].contains(ext)
    }

    @ViewBuilder
    private func fileRow(for download: DownloadedFile, allFiles: [DownloadedFile], index: Int) -> some View {
        let fileContent = HStack(spacing: 12) {
            ThumbnailView(file: download)
                .frame(width: 60, height: 60)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(download.fileName ?? "無題")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack {
                    Text(DownloadService.shared.formatFileSize(download.fileSize))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let date = download.downloadedAt {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)

        Group {
            if isVideoFile(download) {
                // 動画の場合はButtonで直接プレーヤーを開く
                Button(action: {
                    selectedVideoFile = download
                }) {
                    fileContent
                }
                .buttonStyle(.plain)
            } else {
                // 画像やその他のファイルはNavigationLink
                NavigationLink(destination: FileViewerView(
                    file: download,
                    allFiles: allFiles,
                    currentIndex: index
                )) {
                    fileContent
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                DownloadService.shared.deleteFile(download)
                loadDownloads()
            } label: {
                Label("削除", systemImage: "trash")
            }

            Button {
                selectedFile = download
                newFileName = download.fileName ?? ""
                showRenameFile = true
            } label: {
                Label("名前変更", systemImage: "pencil")
            }
            .tint(.blue)

            Button {
                selectedFile = download
                showFolderPicker = true
            } label: {
                Label("移動", systemImage: "folder")
            }
            .tint(.orange)
        }
    }

    private func loadFolders() {
        // ファイルから取得したフォルダ
        let fileFolders = Set(downloads.compactMap { $0.folder })

        // ファイルシステムから実際のフォルダを取得（空フォルダも含む）
        let fileManager = FileManager.default
        let downloadsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Downloads")

        var allFolders = fileFolders
        if let folderContents = try? fileManager.contentsOfDirectory(at: downloadsDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
            for url in folderContents {
                if let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                   resourceValues.isDirectory == true {
                    allFolders.insert(url.lastPathComponent)
                }
            }
        }

        folders = Array(allFolders).filter { !$0.isEmpty }.sorted()

        print("📁 読み込んだフォルダ一覧: \(folders)")
        print("📄 ダウンロード済みファイル数: \(downloads.count)")
    }
}

// フォルダセクション
struct DownloadFolderSection: View {
    let title: String
    let icon: String
    let files: [DownloadedFile]
    let onSelect: (DownloadedFile) -> Void
    let onRename: ((DownloadedFile) -> Void)?
    let onMove: ((DownloadedFile) -> Void)?
    let onDeleteFolder: (() -> Void)?
    let onRenameFolder: (() -> Void)?

    var body: some View {
        Section(header: HStack {
            Image(systemName: icon)
            Text(title)
            Spacer()
            if let onRenameFolder = onRenameFolder {
                Button(action: onRenameFolder) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            if let onDeleteFolder = onDeleteFolder {
                Button(action: onDeleteFolder) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }) {
            if files.isEmpty {
                Text("フォルダは空です")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.vertical, 8)
            } else {
                ForEach(files, id: \.id) { download in
                    Button(action: {
                        onSelect(download)
                    }) {
                        HStack(spacing: 12) {
                            // サムネイル表示
                            ThumbnailView(file: download)
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(download.fileName ?? "無題")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)

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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            DownloadService.shared.deleteFile(download)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }

                        if let onMove = onMove {
                            Button {
                                onMove(download)
                            } label: {
                                Label("移動", systemImage: "folder")
                            }
                            .tint(.blue)
                        }

                        if let onRename = onRename {
                            Button {
                                onRename(download)
                            } label: {
                                Label("リネーム", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        }
    }
}

// サムネイル表示
struct ThumbnailView: View {
    let file: DownloadedFile
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
            } else {
                Color(.systemGray5)
                Image(systemName: iconName)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private var iconName: String {
        guard let fileName = file.fileName else { return "doc" }
        let ext = (fileName as NSString).pathExtension.lowercased()

        if ["mp4", "mov", "avi", "mkv", "webm"].contains(ext) {
            return "video"
        } else if ["jpg", "jpeg", "png", "gif", "webp"].contains(ext) {
            return "photo"
        } else if ["mp3", "wav", "m4a", "flac"].contains(ext) {
            return "music.note"
        } else {
            return "doc"
        }
    }

    private func loadThumbnail() {
        guard let relativePath = file.filePath else { return }
        // 相対パスを絶対パスに変換
        let filePath = DownloadService.shared.getAbsolutePath(from: relativePath)
        let url = URL(fileURLWithPath: filePath)
        let ext = url.pathExtension.lowercased()

        DispatchQueue.global(qos: .userInitiated).async {
            var generatedThumbnail: UIImage?

            if ["jpg", "jpeg", "png", "gif", "webp", "bmp"].contains(ext) {
                // 画像のサムネイル（リサイズして高速化）
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    // 60x60にリサイズして高速化
                    generatedThumbnail = resizeImage(image: image, targetSize: CGSize(width: 120, height: 120))
                }
            } else if ["mp4", "mov", "m4v", "avi", "mkv"].contains(ext) {
                // 動画のサムネイル生成
                generatedThumbnail = generateVideoThumbnail(url: url)
            }

            if let thumbnail = generatedThumbnail {
                DispatchQueue.main.async {
                    self.thumbnail = thumbnail
                }
            }
        }
    }

    private func generateVideoThumbnail(url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 120, height: 120)

        let time = CMTime(seconds: 1, preferredTimescale: 600)

        var thumbnailImage: UIImage?
        let semaphore = DispatchSemaphore(value: 0)

        imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
            if let cgImage = cgImage {
                thumbnailImage = UIImage(cgImage: cgImage)
            }
            semaphore.signal()
        }

        // タイムアウト付きで待機（最大1秒）
        _ = semaphore.wait(timeout: .now() + 1.0)
        return thumbnailImage
    }

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

// フォルダ選択ビュー（ファイル移動用）
struct FolderPickerForMoveView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFolder: String
    let onSelect: (String) -> Void
    @State private var folders: [String] = []
    @State private var showCreateFolder = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationView {
            List {
                // ホーム選択肢
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onSelect("")
                    }
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.blue)
                        Text(NSLocalizedString("downloads.folder.home", comment: ""))
                        Spacer()
                    }
                }

                // フォルダ一覧
                ForEach(folders, id: \.self) { folder in
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onSelect(folder)
                        }
                    }) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text(folder)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("移動先フォルダを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateFolder = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .onAppear {
                loadFolders()
            }
            .alert("新規フォルダ", isPresented: $showCreateFolder) {
                TextField("フォルダ名", text: $newFolderName)
                Button("キャンセル", role: .cancel) {
                    newFolderName = ""
                }
                Button("作成") {
                    createFolder()
                }
            } message: {
                Text("フォルダ名を入力してください")
            }
        }
    }

    private func loadFolders() {
        folders = DownloadService.shared.getAllFolders()
    }

    private func createFolder() {
        guard !newFolderName.isEmpty else { return }

        if DownloadService.shared.createFolder(name: newFolderName) {
            loadFolders()
            newFolderName = ""
        }
    }
}

// ViewModelでView更新をトリガー
class DownloadListViewModel: ObservableObject {
    @Published var updateTrigger = false

    func refresh() {
        updateTrigger.toggle()
    }
}

#Preview {
    DownloadListView()
}
