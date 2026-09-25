import Foundation
import Security

enum KeychainTokenStoreError: LocalizedError {
    case emptyToken
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .emptyToken:
            return "Enter a GitHub token before saving it to the keychain."
        case let .unexpectedStatus(status):
            return SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error \(status)."
        }
    }
}

struct KeychainTokenStore {
    let service = "github-release-downloads"
    let account = NSUserName()

    func hasToken() -> Bool {
        (try? readToken())?.isEmpty == false
    }

    func saveToken(_ token: String) throws {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedToken.isEmpty == false else {
            throw KeychainTokenStoreError.emptyToken
        }

        let encodedToken = Data(trimmedToken.utf8)
        let baseQuery = queryDictionary()
        let attributes: [String: Any] = [kSecValueData as String: encodedToken]
        let status = SecItemCopyMatching(baseQuery as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainTokenStoreError.unexpectedStatus(updateStatus)
            }
        case errSecItemNotFound:
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = encodedToken
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainTokenStoreError.unexpectedStatus(addStatus)
            }
        default:
            throw KeychainTokenStoreError.unexpectedStatus(status)
        }
    }

    func readToken() throws -> String? {
        var query = queryDictionary()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let token = String(data: data, encoding: .utf8) else {
                return nil
            }
            return token
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainTokenStoreError.unexpectedStatus(status)
        }
    }

    func deleteToken() throws {
        let status = SecItemDelete(queryDictionary() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainTokenStoreError.unexpectedStatus(status)
        }
    }

    private func queryDictionary() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
