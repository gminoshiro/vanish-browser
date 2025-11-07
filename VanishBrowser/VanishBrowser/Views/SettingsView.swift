//
//  SettingsView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var autoDeleteService = AutoDeleteService.shared
    @StateObject private var trialManager = TrialManager.shared
    @StateObject private var purchaseManager = PurchaseManager.shared
    @AppStorage("searchEngine") private var searchEngine: String = SearchEngine.duckDuckGo.rawValue
    @AppStorage("authEnabled") private var authEnabled: Bool = false
    @AppStorage("useBiometric") private var useBiometric: Bool = true
    @AppStorage("authPassword") private var authPassword: String = ""
    @State private var showDeleteConfirmation = false
    @State private var storageUsage: (totalBytes: Int64, fileCount: Int) = (0, 0)
    @State private var availableStorage: Int64? = nil
    @State private var showPasscodeSettings = false
    @State private var showCookieManager = false
    @State private var showPurchaseView = false

    var selectedSearchEngine: SearchEngine {
        SearchEngine(rawValue: searchEngine) ?? .google
    }

    var body: some View {
        NavigationView {
            List {
                // Trial/Purchase Status
                Section {
                    if purchaseManager.isPurchased {
                        // Purchased status
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green.gradient)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString("trial.purchased", comment: ""))
                                    .font(.headline)
                                Text(NSLocalizedString("purchase.lifetimeAccess", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if trialManager.isTrialActive {
                        // Trial active
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.badge.checkmark")
                                    .foregroundStyle(.blue.gradient)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(trialManager.getTrialStatusMessage())
                                        .font(.headline)
                                    if let endDate = trialManager.trialEndDate {
                                        Text("終了日: \(trialManager.getTrialEndDateString())")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }

                            Button(action: {
                                showPurchaseView = true
                            }) {
                                Text(NSLocalizedString("purchase.button", comment: ""))
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 8)
                    } else if trialManager.isTrialExpired {
                        // Trial expired
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red.gradient)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("trial.expired", comment: ""))
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    Text(NSLocalizedString("purchase.unlockFeatures", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }

                            Button(action: {
                                showPurchaseView = true
                            }) {
                                Text(NSLocalizedString("purchase.button", comment: ""))
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                        .padding(.vertical, 8)
                    }
                }

                // 一般設定
                Section(header: Text("settings.general").padding(.top, 8)) {
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("settings.setDefaultBrowser")
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundColor(.blue)
                        }
                    }

                    Picker(LocalizedStringKey("settings.searchEngine"), selection: $searchEngine) {
                        ForEach(SearchEngine.allCases, id: \.rawValue) { engine in
                            Text(engine.rawValue).tag(engine.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // セキュリティ設定
                Section(header: Text("settings.security").padding(.top, 8), footer: Text(authEnabled ? (useBiometric ? LocalizedStringKey("settings.security.biometric.footer") : LocalizedStringKey("settings.security.passcode.footer")) : LocalizedStringKey("settings.security.disabled.footer"))) {
                    Toggle(LocalizedStringKey("settings.useAuthentication"), isOn: $authEnabled)
                        .onChange(of: authEnabled) { _, newValue in
                            if newValue && authPassword.isEmpty {
                                // 認証ONにした時にパスコード未設定なら設定画面を表示
                                showPasscodeSettings = true
                            }
                        }

                    if authEnabled {
                        // パスコード設定（生体認証使用時も必須）
                        if !authPassword.isEmpty {
                            HStack {
                                Text("settings.passcodeSet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }

                            Button(LocalizedStringKey("settings.changePasscode")) {
                                showPasscodeSettings = true
                            }

                            Button(LocalizedStringKey("settings.clearPasscode")) {
                                authPassword = ""
                                // パスコードクリア時は生体認証もOFFにする
                                useBiometric = false
                            }
                            .foregroundColor(.red)
                        } else {
                            Button(LocalizedStringKey("settings.setPasscode")) {
                                showPasscodeSettings = true
                            }
                            .foregroundColor(.orange)
                        }

                        // 生体認証トグル（パスコード設定済みの場合のみ有効）
                        Toggle(LocalizedStringKey("settings.useBiometric"), isOn: $useBiometric)
                            .disabled(authPassword.isEmpty)
                            .onChange(of: useBiometric) { _, newValue in
                                if newValue && authPassword.isEmpty {
                                    // パスコード未設定なら警告
                                    useBiometric = false
                                }
                            }
                    }
                }
                // ストレージ情報
                Section(header: Text("settings.storage").padding(.top, 8)) {
                    NavigationLink(destination: DownloadListView()) {
                        HStack {
                            Text("downloads.title")
                            Spacer()
                            Text("\(storageUsage.fileCount)件")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("settings.storage.appUsage")
                        Spacer()
                        Text(formatBytes(storageUsage.totalBytes))
                            .foregroundColor(.secondary)
                    }

                    if let available = availableStorage {
                        HStack {
                            Text("settings.storage.deviceAvailable")
                            Spacer()
                            Text(formatBytes(available))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // データ管理
                Section(header: Text("settings.dataManagement").padding(.top, 8)) {
                    NavigationLink(destination: AutoDeleteSettingsView()) {
                        HStack {
                            Text("settings.autoDelete")
                            Spacer()
                            Text(autoDeleteService.autoDeleteMode.displayShortText)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("settings.deleteAllData.now")
                                .foregroundColor(.red)
                        }
                    }
                }

                // その他
                Section(header: Text("settings.other").padding(.top, 8)) {
                    Button(action: {
                        // App IDは後でApp Store Connectで確認して設定
                        // 開発中は動作しない（App Store公開後に有効）
                        let appID = "YOUR_APP_ID"
                        ReviewManager.shared.openReviewPage(appID: appID)
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("settings.review")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

                    Button(action: {
                        showCookieManager = true
                    }) {
                        HStack {
                            Label(LocalizedStringKey("settings.cookieManager"), systemImage: "folder.badge.gearshape")
                            Spacer()
                        }
                        .foregroundColor(.primary)
                    }

                    NavigationLink(destination: LicenseView()) {
                        Label(LocalizedStringKey("settings.licenses"), systemImage: "doc.text")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(LocalizedStringKey("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("common.close")) {
                        dismiss()
                    }
                }
            }
            .alert(LocalizedStringKey("settings.deleteConfirmTitle"), isPresented: $showDeleteConfirmation) {
                Button(LocalizedStringKey("common.cancel"), role: .cancel) {}
                Button(LocalizedStringKey("common.delete"), role: .destructive) {
                    autoDeleteService.deleteAllData()
                    loadStorageInfo() // 削除後に再読み込み
                }
            } message: {
                Text("settings.deleteConfirmMessage")
            }
            .onAppear {
                loadStorageInfo()
            }
            .sheet(isPresented: $showPasscodeSettings) {
                PasscodeSettingsView()
            }
            .sheet(isPresented: $showCookieManager) {
                CookieManagerView()
            }
            .sheet(isPresented: $showPurchaseView) {
                PurchaseView()
            }
            .onAppear {
                trialManager.updateTrialStatus()
            }
        }
    }

    private func loadStorageInfo() {
        storageUsage = DownloadService.shared.calculateStorageUsage()
        availableStorage = DownloadService.shared.getAvailableStorage()
    }

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes == 0 {
            return "0 KB"
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    SettingsView()
}
