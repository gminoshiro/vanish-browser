//
//  KeychainHelper.swift
//  VanishBrowser
//
//  Helper class for storing data in iCloud Keychain
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    // MARK: - Save

    func save(_ data: Data, forKey key: String) -> Bool {
        // Delete any existing item
        _ = delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: true // Enable iCloud sync
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func save(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, forKey: key)
    }

    func save(_ date: Date, forKey key: String) -> Bool {
        let timestamp = date.timeIntervalSince1970
        let data = withUnsafeBytes(of: timestamp) { Data($0) }
        return save(data, forKey: key)
    }

    // MARK: - Retrieve

    func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecAttrSynchronizable as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func getDate(forKey key: String) -> Date? {
        guard let data = getData(forKey: key) else { return nil }
        guard data.count == MemoryLayout<TimeInterval>.size else { return nil }

        let timestamp = data.withUnsafeBytes { $0.load(as: TimeInterval.self) }
        return Date(timeIntervalSince1970: timestamp)
    }

    // MARK: - Delete

    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrSynchronizable as String: true
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Check Existence

    func exists(forKey key: String) -> Bool {
        return getData(forKey: key) != nil
    }
}
