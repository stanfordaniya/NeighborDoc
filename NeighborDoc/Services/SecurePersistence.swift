import Foundation
import Security

class SecurePersistence {
    static let shared = SecurePersistence()
    
    private init() {}
    
    // MARK: - Keychain Operations
    
    func saveToKeychain(_ data: Data, key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Secure User Data Storage
    
    func saveUserDoc(_ userDoc: UserDoc?) -> Bool {
        guard let userDoc = userDoc else {
            return deleteFromKeychain(key: "userDoc")
        }
        
        guard let data = try? JSONEncoder().encode(userDoc) else { return false }
        return saveToKeychain(data, key: "userDoc")
    }
    
    func loadUserDoc() -> UserDoc? {
        guard let data = loadFromKeychain(key: "userDoc") else { return nil }
        return try? JSONDecoder().decode(UserDoc.self, from: data)
    }
    
    // MARK: - Session Management
    
    func saveSessionTimestamp() {
        var timestamp = Date().timeIntervalSince1970
        let data = Data(bytes: &timestamp, count: MemoryLayout<TimeInterval>.size)
        _ = saveToKeychain(data, key: "sessionTimestamp")
    }
    
    func isSessionValid(maxAge: TimeInterval = 3600) -> Bool { // 1 hour default
        guard let data = loadFromKeychain(key: "sessionTimestamp") else { return false }
        guard data.count == MemoryLayout<TimeInterval>.size else { return false }
        
        let timestamp = data.withUnsafeBytes { $0.load(as: TimeInterval.self) }
        return Date().timeIntervalSince1970 - timestamp < maxAge
    }
    
    func clearAllSecureData() {
        _ = deleteFromKeychain(key: "userDoc")
        _ = deleteFromKeychain(key: "sessionTimestamp")
        _ = deleteFromKeychain(key: "savedDoctorIds")
    }
}
