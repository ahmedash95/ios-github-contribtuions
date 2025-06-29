import Foundation
import Security

class KeychainHelper {
  static let shared = KeychainHelper()

  private let service = "com.contributions.github-token"
  private let account = "github_token"

  private init() {}

  func save(_ token: String) -> Bool {
    guard let data = token.data(using: .utf8) else { return false }

    // Delete any existing item first
    _ = delete()

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
  }

  func load() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess,
      let data = result as? Data,
      let token = String(data: data, encoding: .utf8)
    else {
      return nil
    }
      
    print("Token is: \(token)")

    return token
  }

  func delete() -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]

    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess || status == errSecItemNotFound
  }

  func exists() -> Bool {
    return load() != nil
  }
}
