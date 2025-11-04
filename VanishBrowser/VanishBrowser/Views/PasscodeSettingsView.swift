//
//  PasscodeSettingsView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/18.
//

import SwiftUI

struct PasscodeSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("authPassword") private var authPassword: String = ""

    @State private var currentStep: PasscodeStep = .verifyCurrent
    @State private var firstPasscode: String = ""
    @State private var currentPasscode: String = ""
    @State private var errorMessage: String?
    @State private var passcodeKey: UUID = UUID() // PasscodeViewをリセットするためのキー
    @State private var isChangingPasscode: Bool = false // 変更モードかどうか

    enum PasscodeStep {
        case verifyCurrent  // 現在のパスコード確認（変更時のみ）
        case enterNew       // 新しいパスコード入力
        case confirmNew     // 新しいパスコード確認
        case success        // 完了
    }

    init() {
        // 既存のパスコードがあるかチェック
        let savedPassword = UserDefaults.standard.string(forKey: "authPassword") ?? ""
        _isChangingPasscode = State(initialValue: !savedPassword.isEmpty)
        _currentStep = State(initialValue: savedPassword.isEmpty ? .enterNew : .verifyCurrent)
    }

    var body: some View {
        NavigationView {
            VStack {
                if currentStep == .success {
                    // 成功画面
                    VStack(spacing: 30) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)

                        Text("パスコードが設定されました")
                            .font(.title2)
                            .fontWeight(.medium)

                        Button("完了") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                } else {
                    // パスコード入力画面
                    VStack(spacing: 0) {
                        if let error = errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.top, 40)
                                .padding(.bottom, 20)
                        } else {
                            Spacer()
                                .frame(height: 60)
                        }

                        PasscodeView(
                            title: titleForCurrentStep(),
                            subtitle: subtitleForCurrentStep(),
                            passcode: $currentPasscode,
                            maxDigits: 4
                        ) { enteredPasscode in
                            handlePasscodeEntry(enteredPasscode)
                        }
                        .id(passcodeKey) // キーが変わるとPasscodeViewが再生成される
                    }
                }
            }
            .navigationTitle("パスコード設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func titleForCurrentStep() -> String {
        switch currentStep {
        case .verifyCurrent:
            return "現在のパスコードを入力"
        case .enterNew:
            return isChangingPasscode ? "新しいパスコードを入力" : "パスコードを入力"
        case .confirmNew:
            return "パスコードを再入力"
        case .success:
            return ""
        }
    }

    private func subtitleForCurrentStep() -> String? {
        switch currentStep {
        case .verifyCurrent:
            return "変更するには現在のパスコードが必要です"
        case .enterNew:
            return "4桁の数字を入力してください"
        case .confirmNew:
            return "確認のためもう一度入力してください"
        case .success:
            return nil
        }
    }

    private func handlePasscodeEntry(_ passcode: String) {
        print("🔐 パスコード入力: \(passcode), ステップ: \(currentStep)")

        switch currentStep {
        case .verifyCurrent:
            // 現在のパスコードを確認
            if passcode == authPassword {
                print("✅ 現在のパスコード確認成功")
                currentPasscode = ""
                passcodeKey = UUID()
                currentStep = .enterNew
                errorMessage = nil
            } else {
                print("❌ 現在のパスコードが違います")
                errorMessage = "パスコードが違います"
                currentPasscode = ""
                passcodeKey = UUID()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    errorMessage = nil
                }
            }

        case .enterNew:
            // 新しいパスコード入力
            firstPasscode = passcode
            print("✅ 新しいパスコード保存: \(firstPasscode)")
            currentPasscode = ""
            passcodeKey = UUID()
            currentStep = .confirmNew
            errorMessage = nil

        case .confirmNew:
            // 確認のパスコード入力
            print("🔍 比較: 入力=\(passcode), 保存済み=\(firstPasscode)")
            if passcode == firstPasscode {
                // 一致した場合、保存して成功画面へ
                print("✅ パスコード一致！保存します")
                authPassword = passcode
                currentStep = .success
                errorMessage = nil
            } else {
                // 一致しなかった場合、エラー表示してやり直し
                print("❌ パスコード不一致")
                errorMessage = "パスコードが一致しません"
                firstPasscode = ""
                currentPasscode = ""
                passcodeKey = UUID()
                currentStep = .enterNew

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    errorMessage = nil
                }
            }

        case .success:
            break
        }
    }
}

#Preview {
    PasscodeSettingsView()
}
