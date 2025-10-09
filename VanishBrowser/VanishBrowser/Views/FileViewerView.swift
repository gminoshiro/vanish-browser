//
//  FileViewerView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI
import AVKit

struct FileViewerView: View {
    let file: DownloadedFile
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var image: UIImage?

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
                    // 対応していないファイル
                    VStack(spacing: 16) {
                        Image(systemName: "doc")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text(file.fileName ?? "無題")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("このファイル形式はプレビューできません")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("サイズ: \(DownloadService.shared.formatFileSize(file.fileSize))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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
                    if image != nil || player != nil {
                        ShareLink(item: fileURL) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }
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
        guard let filePath = file.filePath else { return }
        let url = URL(fileURLWithPath: filePath)

        // ファイルの拡張子で判定
        let ext = (file.fileName ?? "").lowercased()

        if ext.hasSuffix(".jpg") || ext.hasSuffix(".jpeg") || ext.hasSuffix(".png") || ext.hasSuffix(".gif") {
            // 画像を読み込み
            if let data = try? Data(contentsOf: url),
               let loadedImage = UIImage(data: data) {
                self.image = loadedImage
            }
        } else if ext.hasSuffix(".mp4") || ext.hasSuffix(".mov") || ext.hasSuffix(".m4v") {
            // 動画プレイヤーを作成
            self.player = AVPlayer(url: url)
        }
    }
}
