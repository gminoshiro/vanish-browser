//
//  FileViewerView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI
import AVKit
import QuickLook
import Combine

struct FileViewerView: View {
    let file: DownloadedFile
    let allFiles: [DownloadedFile]?  // ナビゲーション用
    let currentIndex: Int?  // ナビゲーション用
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var image: UIImage?
    @State private var showQuickLook = false
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isLoading = true
    @State private var showCustomVideoPlayer = false  // カスタムプレーヤー表示用
    @State private var currentFile: DownloadedFile

    init(file: DownloadedFile, allFiles: [DownloadedFile]? = nil, currentIndex: Int? = nil) {
        self.file = file
        self.allFiles = allFiles
        self.currentIndex = currentIndex
        self._currentFile = State(initialValue: file)
        print("🎬 FileViewerView初期化: \(file.fileName ?? "無名")")
        print("🎬 filePath: \(file.filePath ?? "nil")")
    }

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            ProgressView("読み込み中...")
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .foregroundColor(.white)
        } else if let image = image {
            imageView(image: image)
        } else if showCustomVideoPlayer {
            // カスタムプレーヤーはfullScreenCoverで表示されるので透明表示
            Color.clear
        } else {
            QuickLookView(url: fileURL)
        }
    }

    private func imageView(image: UIImage) -> some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width)
                    .scaleEffect(currentScale)
                    .gesture(magnificationGesture)
                    .gesture(doubleTapGesture)
            }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentScale = lastScale * value
            }
            .onEnded { value in
                lastScale = currentScale
                if currentScale < 1.0 {
                    withAnimation {
                        currentScale = 1.0
                        lastScale = 1.0
                    }
                } else if currentScale > 5.0 {
                    withAnimation {
                        currentScale = 5.0
                        lastScale = 5.0
                    }
                }
            }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    if currentScale > 1.0 {
                        currentScale = 1.0
                        lastScale = 1.0
                    } else {
                        currentScale = 2.0
                        lastScale = 2.0
                    }
                }
            }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                contentView

                // ナビゲーションボタン（動画・画像のみ、複数ファイルがある場合）
                if let allFiles = allFiles, let currentIndex = currentIndex, allFiles.count > 1,
                   isMediaFile(currentFile) {
                    HStack {
                        // 前へボタン
                        if currentIndex > 0 {
                            Button(action: navigateToPrevious) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.3)).frame(width: 50, height: 50))
                            }
                            .padding(.leading, 20)
                        } else {
                            Spacer().frame(width: 64)
                        }

                        Spacer()

                        // 次へボタン
                        if currentIndex < allFiles.count - 1 {
                            Button(action: navigateToNext) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.3)).frame(width: 50, height: 50))
                            }
                            .padding(.trailing, 20)
                        } else {
                            Spacer().frame(width: 64)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
            }
            .navigationTitle(currentFile.fileName ?? "無題")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: currentFileURL) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showCustomVideoPlayer, onDismiss: {
            // 動画プレーヤーが閉じられたら、少し待ってからFileViewerViewも閉じる
            print("🎬 動画プレーヤーが閉じられました。0.1秒後にFileViewerViewも閉じます。")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        }) {
            CustomVideoPlayerView(
                videoURL: fileURL,
                videoFileName: file.fileName ?? "無題",
                showDownloadButton: false,  // DL済みなのでDLボタンなし
                isPresented: $showCustomVideoPlayer
            )
        }
        .onAppear {
            print("👁️ FileViewerView.onAppear呼ばれました")
            loadFile()
        }
    }

    private var fileURL: URL {
        guard let relativePath = file.filePath else {
            return URL(fileURLWithPath: "")
        }
        // 相対パスを絶対パスに変換
        let absolutePath = DownloadService.shared.getAbsolutePath(from: relativePath)
        return URL(fileURLWithPath: absolutePath)
    }

    private var currentFileURL: URL {
        guard let relativePath = currentFile.filePath else {
            return URL(fileURLWithPath: "")
        }
        let absolutePath = DownloadService.shared.getAbsolutePath(from: relativePath)
        return URL(fileURLWithPath: absolutePath)
    }

    private func isMediaFile(_ file: DownloadedFile) -> Bool {
        guard let fileName = file.fileName else { return false }
        let ext = (fileName as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "webp", "bmp", "mp4", "mov", "m4v", "avi", "mkv", "webm"].contains(ext)
    }

    private func navigateToPrevious() {
        guard let allFiles = allFiles, let currentIndex = currentIndex, currentIndex > 0 else { return }
        currentFile = allFiles[currentIndex - 1]
        resetAndLoad()
    }

    private func navigateToNext() {
        guard let allFiles = allFiles, let currentIndex = currentIndex, currentIndex < allFiles.count - 1 else { return }
        currentFile = allFiles[currentIndex + 1]
        resetAndLoad()
    }

    private func resetAndLoad() {
        isLoading = true
        image = nil
        player = nil
        currentScale = 1.0
        lastScale = 1.0
        showCustomVideoPlayer = false
        loadFile()
    }

    private func loadFile() {
        guard let relativePath = currentFile.filePath else {
            print("❌ FileViewerView: ファイルパスがありません")
            self.isLoading = false
            return
        }

        // 相対パスを絶対パスに変換
        let filePath = DownloadService.shared.getAbsolutePath(from: relativePath)
        let url = URL(fileURLWithPath: filePath)
        print("📂 FileViewerView: ファイルロード開始")
        print("📂 相対パス: \(relativePath)")
        print("📂 絶対パス: \(filePath)")

        guard FileManager.default.fileExists(atPath: filePath) else {
            print("❌ ファイルが存在しません: \(filePath)")
            self.isLoading = false
            return
        }

        let ext = url.pathExtension.lowercased()
        print("📝 拡張子: \(ext)")

        if ["jpg", "jpeg", "png", "gif", "webp", "bmp"].contains(ext) {
            // 画像を非同期で読み込み
            print("🖼️ 画像として読み込み中: \(filePath)")
            print("🖼️ ファイル存在確認: \(FileManager.default.fileExists(atPath: filePath))")

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    print("🖼️ Data読み込み開始...")
                    let data = try Data(contentsOf: url)
                    print("🖼️ Data読み込み完了: \(data.count) bytes")

                    if let loadedImage = UIImage(data: data) {
                        print("🖼️ UIImage作成成功: \(loadedImage.size)")
                        DispatchQueue.main.async {
                            self.image = loadedImage
                            self.isLoading = false
                            print("✅ 画像表示成功")
                        }
                    } else {
                        print("❌ UIImage作成失敗（dataはあるがUIImageに変換できない）")
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                    }
                } catch {
                    print("❌ 画像読み込みエラー: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }

            // タイムアウト処理（5秒）
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self.isLoading {
                    print("⏱️ 画像読み込みタイムアウト")
                    self.isLoading = false
                }
            }
        } else if ["mp4", "mov", "m4v", "avi", "mkv", "webm", "m3u8"].contains(ext) {
            // カスタム動画プレイヤーを表示（m3u8も含む）
            print("🎬 カスタム動画プレイヤーを表示...")
            DispatchQueue.main.async {
                self.isLoading = false
                self.showCustomVideoPlayer = true
                print("✅ カスタムプレイヤー表示開始: \(url)")
            }
        } else {
            // その他のファイルはQuickLookで表示
            print("📄 QuickLookで表示: \(ext)")
            self.isLoading = false
        }
    }
}

struct QuickLookView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}
