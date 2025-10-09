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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

struct RootView: View {
    @State private var isAuthenticated = false
    @State private var showWarning = false
    @State private var daysLeft = 0
    @State private var showDeleteAlert = false

    var body: some View {
        Group {
            if isAuthenticated || !AppSettingsService.shared.isAuthEnabled() {
                ContentView()
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
            } else {
                AuthenticationView(isAuthenticated: $isAuthenticated)
            }
        }
    }


}
