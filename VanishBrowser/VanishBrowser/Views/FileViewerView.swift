//
//  FileViewerView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI
import AVKit
import QuickLook

struct FileViewerView: View {
    let file: DownloadedFile
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var image: UIImage?
    @State private var showQuickLook = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = image {
                    // 画像表示
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                } else if let player = player {
                    // 動画再生
                    VideoPlayer(player: player)
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    // QuickLookで表示
                    QuickLookView(url: fileURL)
                }
            }
            .navigationTitle(file.fileName ?? "無題")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: fileURL) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
        }
        .onAppear {
            loadFile()
        }
    }

    private var fileURL: URL {
        URL(fileURLWithPath: file.filePath ?? "")
    }

    private func loadFile() {
        guard let filePath = file.filePath else {
            print("❌ FileViewerView: ファイルパスがありません")
            return
        }

        let url = URL(fileURLWithPath: filePath)
        print("📂 FileViewerView: ファイルロード開始: \(filePath)")

        guard FileManager.default.fileExists(atPath: filePath) else {
            print("❌ ファイルが存在しません: \(filePath)")
            return
        }

        let ext = url.pathExtension.lowercased()
        print("📝 拡張子: \(ext)")

        if ["jpg", "jpeg", "png", "gif", "webp", "bmp"].contains(ext) {
            // 画像を読み込み
            print("🖼️ 画像として読み込み中...")
            do {
                let data = try Data(contentsOf: url)
                if let loadedImage = UIImage(data: data) {
                    self.image = loadedImage
                    print("✅ 画像読み込み成功: \(loadedImage.size)")
                } else {
                    print("❌ UIImage作成失敗")
                }
            } catch {
                print("❌ 画像読み込みエラー: \(error)")
            }
        } else if ["mp4", "mov", "m4v", "avi", "mkv"].contains(ext) {
            // 動画プレイヤーを作成
            print("🎬 動画として読み込み中...")
            self.player = AVPlayer(url: url)
            print("✅ 動画プレイヤー作成成功")
        } else {
            // その他のファイルはQuickLookで表示
            print("📄 QuickLookで表示: \(ext)")
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
