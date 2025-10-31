//
//  AuthenticationView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI

struct AuthenticationView: View {
    @Binding var isAuthenticated: Bool
    @State private var password = ""
    @State private var authError: String?
    @State private var showResetAlert = false
    @AppStorage("authEnabled") private var authEnabled: Bool = false
    @AppStorage("authPassword") private var savedPassword: String = ""
    @AppStorage("useBiometric") private var useBiometric: Bool = true

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // 上部: アイコンとタイトル
                    Image(systemName: "lock.shield")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Spacer()
                        .frame(height: 20)

                    Text("Vanish Browser")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if useBiometric && BiometricAuthService.shared.canUseBiometrics() && authError == nil {
                        Spacer()
                            .frame(height: 10)

                        Text("\(BiometricAuthService.shared.biometricType())で認証")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                        .frame(height: 60)

                    // パスコード入力（生体認証失敗時も表示）
                    if !useBiometric || !BiometricAuthService.shared.canUseBiometrics() || authError != nil {
                        VStack(spacing: 0) {
                            if let error = authError {
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .padding(.bottom, 10)
                            }

                            PasscodeView(
                                title: "パスコードを入力",
                                subtitle: nil,
                                passcode: $password,
                                maxDigits: 4
                            ) { enteredPasscode in
                                authenticateWithPassword(enteredPasscode)
                            }

                            // パスコードを忘れた場合のリンク
                            Button("パスコードを忘れた場合") {
                                showResetAlert = true
                            }
                            .font(.footnote)
                            .foregroundColor(.blue)
                            .padding(.top, 10)
                        }
                    }
                }

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .alert("⚠️ すべてのデータを削除", isPresented: $showResetAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除してリセット", role: .destructive) {
                resetPasscode()
            }
        } message: {
            Text("パスコードをリセットするには、セキュリティのためすべてのデータを削除する必要があります。\n\n以下が完全に削除されます：\n• 閲覧履歴\n• ダウンロードファイル\n• ブックマーク\n• パスコード設定\n\nこの操作は取り消せません。本当によろしいですか？")
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // 認証が無効なら自動的に通過
            if !authEnabled {
                isAuthenticated = true
                return
            }

            if useBiometric && BiometricAuthService.shared.canUseBiometrics() {
                authenticate()
            }
        }
    }

    private func authenticate() {
        let reason = "Vanish Browserを開くには認証が必要です"

        BiometricAuthService.shared.authenticate(reason: reason) { success, error in
            if success {
                isAuthenticated = true
            } else {
                // 生体認証失敗時のメッセージ
                if savedPassword.isEmpty {
                    // パスコード未設定の場合
                    authError = "認証に失敗しました。設定でパスコードを設定してください。"
                } else {
                    // パスコード設定済みの場合はパスコード入力にフォールバック
                    authError = "パスコードを入力してください"
                }
            }
        }
    }

    private func authenticateWithPassword(_ enteredPassword: String) {
        if savedPassword.isEmpty {
            // パスワード未設定なら何でもOK
            isAuthenticated = true
        } else if enteredPassword == savedPassword {
            isAuthenticated = true
        } else {
            // 認証失敗時の処理
            authError = "パスコードが違います"

            // パスコードを即座にクリア
            DispatchQueue.main.async {
                password = ""
            }

            // 1.5秒後にエラーメッセージをクリア
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                authError = nil
            }
        }
    }

    private func resetPasscode() {
        print("🗑️ パスコードリセット: すべてのデータを削除します")

        // すべてのデータを削除
        AutoDeleteService.shared.deleteAllData()

        // 認証機能をオフにする
        authEnabled = false
        savedPassword = ""

        print("✅ データ削除完了、アプリに入ります")

        // アプリに入れるようにする
        isAuthenticated = true
    }
}

#Preview {
    AuthenticationView(isAuthenticated: .constant(false))
}
