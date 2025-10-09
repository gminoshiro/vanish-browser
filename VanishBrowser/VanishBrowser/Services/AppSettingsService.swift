//
//  AppSettingsService.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import Foundation
import CoreData

class AppSettingsService {
    static let shared = AppSettingsService()

    private let viewContext = PersistenceController.shared.container.viewContext
    private var settings: AppSettings?

    private init() {
        loadOrCreateSettings()
    }

    // 設定を読み込み、なければ作成
    private func loadOrCreateSettings() {
        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        do {
            let results = try viewContext.fetch(request)
            if let existingSettings = results.first {
                settings = existingSettings
            } else {
                // 初回起動時：デフォルト設定を作成
                let newSettings = AppSettings(context: viewContext)
                newSettings.id = UUID()
                newSettings.autoDeleteDays = 90
                newSettings.deleteWarningDays = 7
                newSettings.lastOpenedAt = Date()
                newSettings.isAuthEnabled = true
                newSettings.defaultSearchEngine = "DuckDuckGo"

                try viewContext.save()
                settings = newSettings
            }
        } catch {
            print("設定読み込みエラー: \(error)")
        }
    }

    // 最終オープン日時を更新
    func updateLastOpenedAt() {
        guard let settings = settings else { return }

        settings.lastOpenedAt = Date()

        do {
            try viewContext.save()
            print("最終オープン日時を更新しました")
        } catch {
            print("設定保存エラー: \(error)")
        }
    }

    // 最終オープン日時を取得
    func getLastOpenedAt() -> Date? {
        return settings?.lastOpenedAt
    }

    // 自動削除日数を取得
    func getAutoDeleteDays() -> Int32 {
        return settings?.autoDeleteDays ?? 90
    }

    // 自動削除日数を設定
    func setAutoDeleteDays(_ days: Int32) {
        guard let settings = settings else { return }

        settings.autoDeleteDays = days

        do {
            try viewContext.save()
            print("自動削除日数を\(days)日に設定しました")
        } catch {
            print("設定保存エラー: \(error)")
        }
    }

    // 削除警告日数を取得
    func getDeleteWarningDays() -> Int32 {
        return settings?.deleteWarningDays ?? 7
    }

    // 生体認証設定を取得
    func isAuthEnabled() -> Bool {
        return settings?.isAuthEnabled ?? true
    }

    // 生体認証設定を変更
    func setAuthEnabled(_ enabled: Bool) {
        guard let settings = settings else { return }

        settings.isAuthEnabled = enabled

        do {
            try viewContext.save()
        } catch {
            print("設定保存エラー: \(error)")
        }
    }

    // デフォルト検索エンジンを取得
    func getDefaultSearchEngine() -> String {
        return settings?.defaultSearchEngine ?? "DuckDuckGo"
    }
}
