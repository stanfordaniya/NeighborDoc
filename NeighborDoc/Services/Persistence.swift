import Foundation

class Persistence {
    static let shared = Persistence()
    let securePersistence = SecurePersistence.shared
    
    private init() {}
    
    func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func save<T: Encodable>(_ object: T, key: String) {
        guard let data = try? JSONEncoder().encode(object) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    // Helper methods for specific data types
    func loadSavedDoctorIds() -> [String] {
        return load([String].self, key: "savedDoctorIds") ?? []
    }
    
    func saveSavedDoctorIds(_ ids: [String]) {
        save(ids, key: "savedDoctorIds")
    }
    
    func loadUserDoc() -> UserDoc? {
        return load(UserDoc.self, key: "userDoc")
    }
    
    func saveUserDoc(_ userDoc: UserDoc?) {
        if let userDoc = userDoc {
            save(userDoc, key: "userDoc")
        } else {
            UserDefaults.standard.removeObject(forKey: "userDoc")
        }
    }
    
    func loadUserDoctor() -> Doctor? {
        return load(Doctor.self, key: "userDoctor")
    }
    
    func saveUserDoctor(_ doctor: Doctor) {
        save(doctor, key: "userDoctor")
    }
    
    func loadCustomDoctors() -> [Doctor] {
        return load([Doctor].self, key: "customDoctors") ?? []
    }
    
    func saveCustomDoctors(_ doctors: [Doctor]) {
        save(doctors, key: "customDoctors")
    }
}
