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
                                title: NSLocalizedString("passcode.enter", comment: ""),
                                subtitle: nil,
                                passcode: $password,
                                maxDigits: 4
                            ) { enteredPasscode in
                                authenticateWithPassword(enteredPasscode)
                            }

                            // パスコードを忘れた場合のリンク
                            Button(NSLocalizedString("auth.forgotPasscode", comment: "")) {
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
        .alert(NSLocalizedString("auth.reset.title", comment: ""), isPresented: $showResetAlert) {
            Button(NSLocalizedString("auth.reset.cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("auth.reset.deleteAndReset", comment: ""), role: .destructive) {
                resetPasscode()
            }
        } message: {
            Text(NSLocalizedString("auth.reset.message", comment: ""))
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
        let reason = NSLocalizedString("auth.biometric.reason", comment: "")

        BiometricAuthService.shared.authenticate(reason: reason) { success, error in
            if success {
                isAuthenticated = true
            } else {
                // 生体認証失敗時のメッセージ
                if savedPassword.isEmpty {
                    // パスコード未設定の場合
                    authError = NSLocalizedString("auth.error.failed", comment: "")
                } else {
                    // パスコード設定済みの場合はパスコード入力にフォールバック
                    authError = NSLocalizedString("auth.error.enterPasscode", comment: "")
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
            authError = NSLocalizedString("passcode.error.incorrect", comment: "")

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
