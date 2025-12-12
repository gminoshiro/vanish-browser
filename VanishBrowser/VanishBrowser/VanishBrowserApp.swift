//
//  VanishBrowserApp.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI
import CoreData

@main
struct VanishBrowserApp: App {
    let persistenceController = PersistenceController.shared
    @State private var importedFileURL: URL?

    init() {
        // アプリ起動カウントを増やす
        ReviewManager.shared.incrementLaunchCount()

        // トライアル期間の初期化と状態更新
        TrialManager.shared.updateTrialStatus()
    }

    var body: some Scene {
        WindowGroup {
            RootView(importedFileURL: $importedFileURL)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    handleIncomingFile(url: url)
                }
                .onAppear {
                    // レビュー依頼チェック
                    ReviewManager.shared.requestReviewIfAppropriate()
                }
        }
    }

    private func handleIncomingFile(url: URL) {
        print("📥 URL受信: \(url)")

        // HTTPまたはHTTPSスキームの場合はブラウザで開く
        if url.scheme == "http" || url.scheme == "https" {
            print("🌐 Webページを開く: \(url.absoluteString)")
            // ブラウザで開くための通知を送信
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenExternalURL"),
                object: nil,
                userInfo: ["url": url.absoluteString]
            )
            return
        }

        // ファイル共有の処理
        print("📥 ファイル共有を受信: \(url)")

        // セキュリティスコープ付きリソースへのアクセス開始
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ セキュリティスコープへのアクセス失敗")
            return
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }

        // ファイルをアプリのDownloadsディレクトリにコピー
        let fileName = url.lastPathComponent
        let downloadsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Downloads")

        do {
            // Downloadsディレクトリを作成（存在しない場合）
            try FileManager.default.createDirectory(at: downloadsURL, withIntermediateDirectories: true)

            let destinationURL = downloadsURL.appendingPathComponent(fileName)

            // 同名ファイルがある場合はファイル名を変更
            var finalURL = destinationURL
            var counter = 1
            while FileManager.default.fileExists(atPath: finalURL.path) {
                let nameWithoutExt = url.deletingPathExtension().lastPathComponent
                let ext = url.pathExtension
                finalURL = downloadsURL.appendingPathComponent("\(nameWithoutExt)_\(counter).\(ext)")
                counter += 1
            }

            // ファイルをコピー
            try FileManager.default.copyItem(at: url, to: finalURL)
            print("✅ ファイルコピー成功: \(finalURL)")

            // DownloadServiceに登録
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: finalURL.path)[.size] as? Int64) ?? 0
            let mimeType = getMimeType(for: finalURL)

            DownloadService.shared.saveDownloadedFile(
                fileName: finalURL.lastPathComponent,
                filePath: finalURL.path,
                fileSize: fileSize,
                mimeType: mimeType,
                folder: nil
            )

            // UIに通知（ダウンロード一覧を表示）
            importedFileURL = finalURL

        } catch {
            print("❌ ファイルコピー失敗: \(error)")
        }
    }

    private func getMimeType(for url: URL) -> String? {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "pdf": return "application/pdf"
        default: return nil
        }
    }
}

struct RootView: View {
    @Binding var importedFileURL: URL?
    @StateObject private var trialManager = TrialManager.shared
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var isAuthenticated = false
    @State private var showWarning = false
    @State private var daysLeft = 0
    @State private var showDeleteAlert = false
    @State private var showImportSuccess = false
    @State private var showTrialWelcome = false

    var body: some View {
        Group {
            if isAuthenticated || !AppSettingsService.shared.isAuthEnabled() {
                ContentView()
                    .fullScreenCover(isPresented: .constant(trialManager.shouldShowPaywall())) {
                        PurchaseView()
                            .interactiveDismissDisabled(true)
                    }
                    .alert("データ削除警告", isPresented: $showWarning) {
                        Button("OK") {}
                    } message: {
                        Text("あと\(daysLeft)日でアプリを起動しないと、全データが自動削除されます。")
                    }
                    .alert("データが削除されました", isPresented: $showDeleteAlert) {
                        Button("OK") {}
                    } message: {
                        Text("90日間アプリを起動しなかったため、全てのデータが削除されました。")
                    }
                    .alert("ファイルを保存しました", isPresented: $showImportSuccess) {
                        Button("OK") {}
                    } message: {
                        if let url = importedFileURL {
                            Text("\(url.lastPathComponent)をダウンロードフォルダに保存しました。")
                        }
                    }
                    .onChange(of: importedFileURL) { newValue in
                        if newValue != nil {
                            showImportSuccess = true
                        }
                    }
                    .alert("7日間無料でお試し", isPresented: $showTrialWelcome) {
                        Button("始める") {
                            trialManager.markTrialWelcomeAsShown()
                        }
                    } message: {
                        Text("すべての機能を7日間、無料でお使いいただけます。\n\n期間終了後、¥300の買い切り購入で引き続きご利用いただけます。月額課金はありません。")
                    }
                    .onAppear {
                        // Check if we should show trial welcome alert
                        if trialManager.shouldShowTrialWelcome() {
                            showTrialWelcome = true
                        }
                    }
            } else {
                AuthenticationView(isAuthenticated: $isAuthenticated)
            }
        }
    }
}
