//
//  AuthenticationView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI

struct AuthenticationView: View {
    @Binding var isAuthenticated: Bool
    @State private var authError: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Vanish Browser")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("\(BiometricAuthService.shared.biometricType())で認証してください")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                authenticate()
            }) {
                HStack {
                    Image(systemName: biometricIcon())
                    Text("認証する")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: 200)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.top, 20)

            if let error = authError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            authenticate()
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
                showError = true
            }
        }
    }

    private func biometricIcon() -> String {
        let type = BiometricAuthService.shared.biometricType()
        switch type {
        case "Face ID":
            return "faceid"
        case "Touch ID":
            return "touchid"
        default:
            return "lock.shield"
        }
    }
}

#Preview {
    AuthenticationView(isAuthenticated: .constant(false))
}
