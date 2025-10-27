//
//  CustomVideoPlayerView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/12.
//

import SwiftUI
import AVKit
import Combine

struct CustomVideoPlayerView: View {
    let videoURL: URL
    let videoFileName: String
    let showDownloadButton: Bool  // DLボタンの表示/非表示
    @Binding var isPresented: Bool
    @StateObject private var playerViewModel: VideoPlayerViewModel
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var showDownloadDialog = false
    @State private var showShareSheet = false

    init(videoURL: URL, videoFileName: String, showDownloadButton: Bool = true, isPresented: Binding<Bool>) {
        print("🎬 CustomVideoPlayerView初期化")
        print("🎬 videoURL: \(videoURL.absoluteString)")
        print("🎬 videoFileName: \(videoFileName)")
        print("🎬 showDownloadButton: \(showDownloadButton)")
        print("🎬 ファイル存在: \(FileManager.default.fileExists(atPath: videoURL.path))")

        self.videoURL = videoURL
        self.videoFileName = videoFileName
        self.showDownloadButton = showDownloadButton
        self._isPresented = isPresented
        self._playerViewModel = StateObject(wrappedValue: VideoPlayerViewModel(url: videoURL))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                // カスタムビデオプレーヤー（AVPlayerLayerを直接使用）
                CustomAVPlayerView(player: playerViewModel.player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        toggleControls()
                    }

                // カスタムコントロール
                if showControls {
                    VStack(spacing: 0) {
                        // 上部: 閉じるボタン（左上）と共有ボタン（右上、DL済みのみ）
                        HStack {
                            // 左上: ×ボタン
                            Button(action: {
                                isPresented = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            // 右上: 共有ボタン（DL済み動画のみ表示）
                            if !showDownloadButton {  // DL済み動画（showDownloadButton=falseの場合）
                                Button(action: {
                                    showShareSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, max(geometry.safeAreaInsets.top, 16))
                        .padding(.bottom, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        Spacer()

                        // 下部: 再生コントロール
                        VStack(spacing: 12) {
                            // シークバー
                            HStack(spacing: 8) {
                                Text(formatTime(playerViewModel.currentTime))
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .monospacedDigit()

                                Slider(
                                    value: Binding(
                                        get: { playerViewModel.currentTime },
                                        set: { playerViewModel.seek(to: $0) }
                                    ),
                                    in: 0...max(playerViewModel.duration, 1)
                                )
                                .accentColor(.white)

                                Text(formatTime(playerViewModel.duration))
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, 20)

                            // 再生ボタンとダウンロードボタン
                            HStack(spacing: 24) {
                                // ダウンロードボタン（DL前のみ表示）
                                if showDownloadButton {
                                    Button(action: {
                                        print("📥 DLボタン押下: \(videoFileName)")
                                        print("📥 URL: \(videoURL.absoluteString)")
                                        // プレーヤーを閉じずにダイアログを表示
                                        playerViewModel.pause()
                                        showDownloadDialog = true
                                    }) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.white)
                                            .background(
                                                Circle()
                                                    .fill(Color.blue)
                                                    .frame(width: 36, height: 36)
                                            )
                                    }
                                }

                                Spacer()

                                // 巻き戻しボタン
                                Button(action: {
                                    playerViewModel.skipBackward()
                                }) {
                                    Image(systemName: "gobackward.10")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }

                                // 再生/一時停止ボタン
                                Button(action: {
                                    playerViewModel.togglePlayPause()
                                }) {
                                    Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.white)
                                }

                                // 早送りボタン
                                Button(action: {
                                    playerViewModel.skipForward()
                                }) {
                                    Image(systemName: "goforward.10")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }

                                Spacer()

                                // その他メニュー
                                Menu {
                                    Button(action: {
                                        playerViewModel.changeSpeed(0.5)
                                    }) {
                                        Label("0.5x", systemImage: "speedometer")
                                    }
                                    Button(action: {
                                        playerViewModel.changeSpeed(1.0)
                                    }) {
                                        Label("1.0x (標準)", systemImage: "speedometer")
                                    }
                                    Button(action: {
                                        playerViewModel.changeSpeed(1.5)
                                    }) {
                                        Label("1.5x", systemImage: "speedometer")
                                    }
                                    Button(action: {
                                        playerViewModel.changeSpeed(2.0)
                                    }) {
                                        Label("2.0x", systemImage: "speedometer")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                        }
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            playerViewModel.play()
            scheduleHideControls()
        }
        .onDisappear {
            playerViewModel.pause()
        }
        .sheet(isPresented: $showDownloadDialog) {
            DownloadDialogView(
                fileName: .constant(videoFileName),
                videoURL: videoURL,
                onDownload: { fileName, folder in
                    // 通常ダウンロード
                    DownloadManager.shared.startDownload(url: videoURL, fileName: fileName, folder: folder)
                    isPresented = false
                },
                onHLSDownload: { quality, format, fileName, folder in
                    // HLSダウンロード
                    NotificationCenter.default.post(
                        name: NSNotification.Name("StartHLSDownload"),
                        object: nil,
                        userInfo: [
                            "quality": quality,
                            "format": format,
                            "fileName": fileName,
                            "folder": folder
                        ]
                    )
                    isPresented = false
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [videoURL])
        }
    }

    private func toggleControls() {
        withAnimation {
            showControls.toggle()
        }
        if showControls {
            scheduleHideControls()
        }
    }

    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3秒
            withAnimation {
                showControls = false
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// ビデオプレーヤーのViewModel
class VideoPlayerViewModel: NSObject, ObservableObject {
    let player: AVPlayer
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying: Bool = false

    private var timeObserver: Any?

    init(url: URL) {
        print("🎥 VideoPlayerViewModel初期化: \(url.absoluteString)")
        print("🎥 ファイル存在確認: \(FileManager.default.fileExists(atPath: url.path))")

        self.player = AVPlayer(url: url)

        super.init()

        // AVPlayerのステータス監視
        player.currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)

        // 再生時間の監視
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            self?.currentTime = time.seconds
        }

        // 動画の長さを取得
        player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                if let duration = self?.player.currentItem?.asset.duration {
                    self?.duration = CMTimeGetSeconds(duration)
                    print("🎥 動画の長さ: \(CMTimeGetSeconds(duration))秒")
                }
            }
        }

        // エラー監視
        if let error = player.currentItem?.error {
            print("❌ AVPlayerエラー: \(error.localizedDescription)")
        }

        // 再生状態の監視
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let statusNumber = change?[.newKey] as? NSNumber {
                let status = AVPlayerItem.Status(rawValue: statusNumber.intValue)
                switch status {
                case .readyToPlay:
                    print("✅ AVPlayer: 再生準備完了")
                case .failed:
                    if let error = player.currentItem?.error {
                        print("❌ AVPlayer: 再生失敗 - \(error.localizedDescription)")
                    }
                case .unknown:
                    print("⚠️ AVPlayer: ステータス不明")
                default:
                    break
                }
            }
        }
    }

    deinit {
        player.currentItem?.removeObserver(self, forKeyPath: "status")
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }

    func play() {
        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: Double) {
        player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    func skipForward() {
        let newTime = min(currentTime + 10, duration)
        seek(to: newTime)
    }

    func skipBackward() {
        let newTime = max(currentTime - 10, 0)
        seek(to: newTime)
    }

    func changeSpeed(_ rate: Float) {
        player.rate = rate
        if isPlaying {
            player.play()
        }
    }
}

// カスタムAVPlayerView（AVPlayerLayerを直接使用してViewControllerを回避）
struct CustomAVPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView()
        view.playerLayer.player = player

        // 標準プレーヤーの表示を完全に無効化
        view.playerLayer.videoGravity = .resizeAspect

        print("✅ CustomAVPlayerView作成完了（AVPlayerLayerを直接使用）")
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 必要に応じて更新処理
    }

    // カスタムUIView（AVPlayerLayerを直接保持）
    class PlayerUIView: UIView {
        override class var layerClass: AnyClass {
            return AVPlayerLayer.self
        }

        var playerLayer: AVPlayerLayer {
            return layer as! AVPlayerLayer
        }
    }
}
