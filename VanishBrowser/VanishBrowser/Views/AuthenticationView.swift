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
    @AppStorage("authEnabled") private var authEnabled: Bool = false
    @AppStorage("authPassword") private var savedPassword: String = ""
    @AppStorage("useBiometric") private var useBiometric: Bool = true

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 上部: アイコンとタイトル
                VStack(spacing: 30) {
                    Spacer()

                    Image(systemName: "lock.shield")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Vanish Browser")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if useBiometric && BiometricAuthService.shared.canUseBiometrics() {
                        Text("\(BiometricAuthService.shared.biometricType())で認証")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .frame(height: geometry.size.height * 0.5)

                // 下部: パスワード入力欄とボタン
                if !useBiometric || !BiometricAuthService.shared.canUseBiometrics() {
                    VStack(spacing: 20) {
                        Text("パスワードを入力")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        SecureField("パスワード", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 40)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .onSubmit {
                                authenticateWithPassword()
                            }

                        Button("認証する") {
                            authenticateWithPassword()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.blue)
                        .cornerRadius(10)

                        if let error = authError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                    .padding(.bottom, 40)
                }

                Spacer()
            }
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
                if let error = error {
                    authError = error.localizedDescription
                } else {
                    authError = "認証に失敗しました"
                }
            }
        }
    }

    private func authenticateWithPassword() {
        if savedPassword.isEmpty {
            // パスワード未設定なら何でもOK
            isAuthenticated = true
        } else if password == savedPassword {
            isAuthenticated = true
        } else {
            authError = "パスワードが違います"
            password = ""
        }
    }
}

#Preview {
    AuthenticationView(isAuthenticated: .constant(false))
}
