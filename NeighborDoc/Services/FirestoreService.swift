import Foundation
import FirebaseFirestore
import Combine

enum NetworkError: Error {
    case rateLimitExceeded
    case networkUnavailable
    case invalidRequest
}

class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    private let doctorsCollection = "doctors"
    private let networkSecurity = NetworkSecurity.shared
    
    // MARK: - Doctor Operations
    
    /// Add a new doctor to Firestore
    func addDoctor(_ doctor: Doctor) async throws {
        // Validate network security
        guard networkSecurity.canMakeRequest() else {
            throw NetworkError.rateLimitExceeded
        }
        
        networkSecurity.recordRequest()
        try db.collection(doctorsCollection).document(doctor.id).setData(from: doctor)
    }
    
    /// Update an existing doctor in Firestore
    func updateDoctor(_ doctor: Doctor) async throws {
        // Validate network security
        guard networkSecurity.canMakeRequest() else {
            throw NetworkError.rateLimitExceeded
        }
        
        networkSecurity.recordRequest()
        try db.collection(doctorsCollection).document(doctor.id).setData(from: doctor, merge: true)
    }
    
    /// Delete a doctor from Firestore
    func deleteDoctor(id: String) async throws {
        // Validate network security
        guard networkSecurity.canMakeRequest() else {
            throw NetworkError.rateLimitExceeded
        }
        
        networkSecurity.recordRequest()
        try await db.collection(doctorsCollection).document(id).delete()
    }
    
    /// Fetch all doctors from Firestore
    func fetchDoctors() async throws -> [Doctor] {
        let snapshot = try await db.collection(doctorsCollection).getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Doctor.self)
        }
    }
    
    /// Fetch doctors with filters
    func fetchDoctors(
        cityOrZip: String? = nil,
        specialty: String? = nil,
        race: String? = nil,
        doctorName: String? = nil
    ) async throws -> [Doctor] {
        var query: Query = db.collection(doctorsCollection)
        
        // Add filters
        if let cityOrZip = cityOrZip, !cityOrZip.isEmpty {
            query = query.whereField("city", isGreaterThanOrEqualTo: cityOrZip)
                .whereField("city", isLessThan: cityOrZip + "\u{f8ff}")
        }
        
        if let specialty = specialty, !specialty.isEmpty {
            query = query.whereField("specialty", isEqualTo: specialty)
        }
        
        if let race = race, !race.isEmpty {
            query = query.whereField("raceEthnicity", isEqualTo: race)
        }
        
        // Filter for active doctors only
        query = query.whereField("isActive", isEqualTo: true)
        
        let snapshot = try await query.getDocuments()
        var doctors = snapshot.documents.compactMap { document in
            try? document.data(as: Doctor.self)
        }
        
        // Apply client-side filters for complex queries
        if let doctorName = doctorName, !doctorName.isEmpty {
            doctors = doctors.filter { doctor in
                doctor.name.localizedCaseInsensitiveContains(doctorName)
            }
        }
        
        if let cityOrZip = cityOrZip, !cityOrZip.isEmpty {
            doctors = doctors.filter { doctor in
                doctor.city.localizedCaseInsensitiveContains(cityOrZip) ||
                doctor.state.localizedCaseInsensitiveContains(cityOrZip) ||
                doctor.zipCode.localizedCaseInsensitiveContains(cityOrZip)
            }
        }
        
        return doctors
    }
    
    /// Listen to real-time updates for doctors
    func listenToDoctors() -> AnyPublisher<[Doctor], Error> {
        return Future<[Doctor], Error> { promise in
            self.db.collection(self.doctorsCollection)
                .whereField("isActive", isEqualTo: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    let doctors = snapshot?.documents.compactMap { document in
                        try? document.data(as: Doctor.self)
                    } ?? []
                    
                    promise(.success(doctors))
                }
        }
        .eraseToAnyPublisher()
    }
    
    /// Get a specific doctor by ID
    func getDoctor(id: String) async throws -> Doctor? {
        let document = try await db.collection(doctorsCollection).document(id).getDocument()
        return try? document.data(as: Doctor.self)
    }
    
    // MARK: - User Operations
    
    /// Save user's saved doctor IDs to Firestore
    func saveUserSavedDoctors(userId: String, savedDoctorIds: [String]) async throws {
        try await db.collection("users").document(userId).setData([
            "savedDoctorIds": savedDoctorIds
        ], merge: true)
    }
    
    /// Get user's saved doctor IDs from Firestore
    func getUserSavedDoctors(userId: String) async throws -> [String] {
        let document = try await db.collection("users").document(userId).getDocument()
        return document.data()?["savedDoctorIds"] as? [String] ?? []
    }
    
    /// Delete a user from Firestore
    func deleteUser(_ userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).delete { error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
    
    /// Delete a doctor from Firestore (callback version for compatibility)
    func deleteDoctor(_ doctorId: String, completion: @escaping (Bool) -> Void) {
        db.collection(doctorsCollection).document(doctorId).delete { error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// Sync local doctors to Firestore
    func syncDoctorsToFirestore(_ doctors: [Doctor]) async throws {
        let batch = db.batch()
        
        for doctor in doctors {
            let docRef = db.collection(doctorsCollection).document(doctor.id)
            try batch.setData(from: doctor, forDocument: docRef)
        }
        
        try await batch.commit()
    }
}
