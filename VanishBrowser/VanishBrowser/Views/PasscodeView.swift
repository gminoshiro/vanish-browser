//
//  PasscodeView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/18.
//

import SwiftUI

struct PasscodeView: View {
    let title: String
    let subtitle: String?
    @Binding var passcode: String
    let maxDigits: Int
    let onComplete: (String) -> Void

    @State private var enteredDigits: [String] = []

    init(
        title: String,
        subtitle: String? = nil,
        passcode: Binding<String>,
        maxDigits: Int = 4,
        onComplete: @escaping (String) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self._passcode = passcode
        self.maxDigits = maxDigits
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            // パスコード表示（ドット）
            HStack(spacing: 20) {
                ForEach(0..<maxDigits, id: \.self) { index in
                    ZStack {
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.3), lineWidth: 2)
                            .frame(width: 16, height: 16)

                        if index < enteredDigits.count {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .padding(.vertical, 20)

            Spacer()
                .frame(height: 20)

            // 数字キーパッド
            VStack(spacing: 12) {
                // 1-3
                HStack(spacing: 20) {
                    ForEach(1...3, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            addDigit("\(number)")
                        }
                    }
                }

                // 4-6
                HStack(spacing: 20) {
                    ForEach(4...6, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            addDigit("\(number)")
                        }
                    }
                }

                // 7-9
                HStack(spacing: 20) {
                    ForEach(7...9, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            addDigit("\(number)")
                        }
                    }
                }

                // 削除-0-空白
                HStack(spacing: 20) {
                    // 削除ボタン
                    Button(action: removeDigit) {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .frame(width: 70, height: 70)
                    }
                    .buttonStyle(.plain)

                    // 0
                    NumberButton(number: "0") {
                        addDigit("0")
                    }

                    // 空白（バランス調整用）
                    Color.clear
                        .frame(width: 70, height: 70)
                }
            }
        }
        .onChange(of: passcode) { oldValue, newValue in
            // passcodeが外部から空にされた場合、enteredDigitsもクリア
            if newValue.isEmpty && !enteredDigits.isEmpty {
                enteredDigits.removeAll()
            }
        }
    }

    private func addDigit(_ digit: String) {
        guard enteredDigits.count < maxDigits else { return }

        enteredDigits.append(digit)
        passcode = enteredDigits.joined()

        // 最大桁数に達したら完了処理を実行
        if enteredDigits.count == maxDigits {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onComplete(passcode)
            }
        }
    }

    private func removeDigit() {
        guard !enteredDigits.isEmpty else { return }
        enteredDigits.removeLast()
        passcode = enteredDigits.joined()
    }

    func reset() {
        enteredDigits.removeAll()
        passcode = ""
    }
}

// 数字ボタンコンポーネント
struct NumberButton: View {
    let number: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(.primary)
                .frame(width: 70, height: 70)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PasscodeView(
        title: "パスコードを入力",
        subtitle: nil,
        passcode: .constant(""),
        maxDigits: 4
    ) { passcode in
        print("入力されたパスコード: \(passcode)")
    }
}
