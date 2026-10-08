import Foundation
import Security

protocol SecretStore: AnyObject {
    var pairedHashes: [String] { get set }
    var emergencyUnlocksUsed: Int { get set }
    var appleUserID: String? { get set }
    var displayName: String? { get set }
}

final class MemorySecretStore: SecretStore {
    var pairedHashes: [String] = []
    var emergencyUnlocksUsed: Int = 0
    var appleUserID: String?
    var displayName: String?
}

final class KeychainStore: SecretStore {
    private let service = AppConfig.bundleIdentifier

    var pairedHashes: [String] {
        get {
            guard let data = data(for: "pairedTagHashes") else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            set(data, for: "pairedTagHashes")
        }
    }

    var emergencyUnlocksUsed: Int {
        get {
            guard let data = data(for: "emergencyUnlocksUsed"),
                  let raw = String(data: data, encoding: .utf8),
                  let value = Int(raw) else {
                return 0
            }
            return max(0, value)
        }
        set {
            set(Data(String(max(0, newValue)).utf8), for: "emergencyUnlocksUsed")
        }
    }

    var appleUserID: String? {
        get { string(for: "appleUserID") }
        set { setString(newValue, for: "appleUserID") }
    }

    var displayName: String? {
        get { string(for: "displayName") }
        set { setString(newValue, for: "displayName") }
    }

    private func string(for account: String) -> String? {
        guard let data = data(for: account) else { return nil }
        let value = String(data: data, encoding: .utf8)
        return (value?.isEmpty == false) ? value : nil
    }

    private func setString(_ value: String?, for account: String) {
        guard let value, !value.isEmpty else {
            set(nil, for: account)
            return
        }
        set(Data(value.utf8), for: account)
    }

    private func data(for account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    private func set(_ data: Data?, for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(query as CFDictionary)
        guard let data else { return }
        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        insert[kSecAttrSynchronizable as String] = kCFBooleanTrue
        SecItemAdd(insert as CFDictionary, nil)
    }
}
