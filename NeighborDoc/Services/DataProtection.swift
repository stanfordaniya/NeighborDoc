import Foundation
import CryptoKit

class DataProtection {
    static let shared = DataProtection()
    
    private init() {}
    
    // MARK: - Data Encryption
    
    func encryptData(_ data: Data, key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("❌ Encryption failed: \(error)")
            return nil
        }
    }
    
    func decryptData(_ encryptedData: Data, key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("❌ Decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Key Generation
    
    func generateKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    func generateKeyFromPassword(_ password: String) -> SymmetricKey {
        let salt = "NeighborDoc_Salt_2024".data(using: .utf8)!
        let keyData = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: password.data(using: .utf8)!),
            salt: salt,
            outputByteCount: 32
        )
        return keyData
    }
    
    // MARK: - Data Anonymization
    
    func anonymizeDoctorData(_ doctor: Doctor) -> Doctor {
        var anonymized = doctor
        // Remove or hash sensitive information
        anonymized.phoneNumber = nil
        anonymized.ownerUid = nil
        return anonymized
    }
    
    // MARK: - Data Retention
    
    func shouldRetainData(_ timestamp: Date, retentionPeriod: TimeInterval = 31536000) -> Bool {
        // Default: 1 year retention
        return Date().timeIntervalSince(timestamp) < retentionPeriod
    }
    
    func cleanupExpiredData() {
        // Implement data cleanup based on retention policies
        _ = Date().addingTimeInterval(-31536000) // 1 year ago
        
        // Clean up old search history, cached data, etc.
        UserDefaults.standard.removeObject(forKey: "oldSearchHistory")
        UserDefaults.standard.removeObject(forKey: "cachedData")
    }
    
    // MARK: - Privacy Controls
    
    func canAccessLocation() -> Bool {
        // Check if user has granted location permission
        return true // Implement proper location permission checking
    }
    
    func canAccessContacts() -> Bool {
        // Check if user has granted contacts permission
        return false // Implement proper contacts permission checking
    }
    
    // MARK: - Data Export/Import Security
    
    func validateImportedData(_ data: Data) -> Bool {
        // Validate data structure and content
        do {
            let doctors = try JSONDecoder().decode([Doctor].self, from: data)
            
            // Check for malicious content
            for doctor in doctors {
                if InputValidator.shared.containsXSSPatterns(doctor.name) ||
                   InputValidator.shared.containsSQLInjectionPatterns(doctor.name) {
                    return false
                }
            }
            
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Secure Data Transmission
    
    func prepareDataForTransmission(_ data: Data) -> Data? {
        // Add integrity checks, timestamps, etc.
        var timestamp = Date().timeIntervalSince1970
        let timestampData = Data(bytes: &timestamp, count: MemoryLayout<TimeInterval>.size)
        
        var combinedData = Data()
        combinedData.append(timestampData)
        combinedData.append(data)
        
        // Add checksum
        let checksum = SHA256.hash(data: combinedData)
        combinedData.append(Data(checksum))
        
        return combinedData
    }
}
