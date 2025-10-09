//
//  BiometricAuthService.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import Foundation
import LocalAuthentication

class BiometricAuthService {
    static let shared = BiometricAuthService()

    private init() {}

    // 生体認証が利用可能かチェック
    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // 生体認証のタイプを取得
    func biometricType() -> String {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "パスコード"
        }

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "パスコード"
        @unknown default:
            return "生体認証"
        }
    }

    // 認証実行
    func authenticate(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        // 生体認証が使えない場合はパスコード認証にフォールバック
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // パスコード認証を試す
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    completion(success, authError)
                }
            }
            return
        }

        // 生体認証を実行
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                completion(success, authError)
            }
        }
    }
}
