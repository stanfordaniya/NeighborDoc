import Foundation
import FirebaseFirestore
import Combine

class DirectoryStore: ObservableObject {
    static let shared = DirectoryStore()
    
    @Published var seedDoctors: [Doctor] = []
    @Published var customDoctors: [Doctor] = []
    @Published var firestoreDoctors: [Doctor] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistence = Persistence.shared
    private let firestoreService = FirestoreService()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSeedDoctors()
        loadCustomDoctors()
        setupFirestoreListener()
    }
    
    var allDoctors: [Doctor] {
        let seed = seedDoctors.filter { $0.isActive != false }
        let custom = customDoctors.filter { $0.isActive != false }
        let firestore = firestoreDoctors.filter { $0.isActive != false }
        let total = seed + custom + firestore
        return total
    }
    
    private func loadSeedDoctors() {
        guard let url = Bundle.main.url(forResource: "doctors", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let doctors = try? JSONDecoder().decode([Doctor].self, from: data) else {
            return
        }
        seedDoctors = doctors
    }
    
    private func loadCustomDoctors() {
        customDoctors = persistence.loadCustomDoctors()
    }
    
    func search(doctorName: String?, cityOrZip: String?, specialty: String?, race: String?) -> [Doctor] {
        var results = allDoctors
        
        if let doctorName = doctorName, !doctorName.isEmpty {
            results = results.filter { doctor in
                doctor.name.localizedCaseInsensitiveContains(doctorName)
            }
        }
        
        if let cityOrZip = cityOrZip, !cityOrZip.isEmpty {
            results = results.filter { doctor in
                doctor.city.localizedCaseInsensitiveContains(cityOrZip) ||
                doctor.state.localizedCaseInsensitiveContains(cityOrZip) ||
                doctor.zipCode.localizedCaseInsensitiveContains(cityOrZip)
            }
        }
        
        if let specialty = specialty, !specialty.isEmpty {
            results = results.filter { $0.specialty == specialty }
        }
        
        if let race = race, !race.isEmpty {
            results = results.filter { $0.raceEthnicity == race }
        }
        
        return results
    }
    
    func doctor(id: String) -> Doctor? {
        return allDoctors.first { $0.id == id }
    }
    
    func upsertCustomDoctor(_ doctor: Doctor) {
        if let index = customDoctors.firstIndex(where: { $0.id == doctor.id }) {
            customDoctors[index] = doctor
        } else {
            customDoctors.append(doctor)
        }
        persistence.saveCustomDoctors(customDoctors)
        objectWillChange.send()
    }
    
    func setActive(_ id: String, active: Bool) {
        if let index = customDoctors.firstIndex(where: { $0.id == id }) {
            customDoctors[index].isActive = active
            persistence.saveCustomDoctors(customDoctors)
            objectWillChange.send()
        }
    }
    
    // MARK: - Firestore Integration
    
    private func setupFirestoreListener() {
        print("🔥 Setting up Firestore listener...")
        firestoreService.listenToDoctors()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Firestore error: \(error.localizedDescription)")
                        self?.errorMessage = "Failed to sync with Firestore: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] doctors in
                    print("✅ Loaded \(doctors.count) doctors from Firestore")
                    self?.firestoreDoctors = doctors
                    self?.objectWillChange.send()
                }
            )
            .store(in: &cancellables)
    }
    
    /// Sync local custom doctors to Firestore
    func syncCustomDoctorsToFirestore() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firestoreService.syncDoctorsToFirestore(customDoctors)
        } catch {
            errorMessage = "Failed to sync doctors: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Add a doctor to both local storage and Firestore
    func addDoctorToFirestore(_ doctor: Doctor) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firestoreService.addDoctor(doctor)
            // Also update local storage
            upsertCustomDoctor(doctor)
        } catch {
            errorMessage = "Failed to add doctor: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Update a doctor in both local storage and Firestore
    func updateDoctorInFirestore(_ doctor: Doctor) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firestoreService.updateDoctor(doctor)
            // Also update local storage
            upsertCustomDoctor(doctor)
        } catch {
            errorMessage = "Failed to update doctor: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Search doctors in Firestore
    func searchInFirestore(
        doctorName: String? = nil,
        cityOrZip: String? = nil,
        specialty: String? = nil,
        race: String? = nil
    ) async -> [Doctor] {
        isLoading = true
        errorMessage = nil
        
        do {
            let doctors = try await firestoreService.fetchDoctors(
                cityOrZip: cityOrZip,
                specialty: specialty,
                race: race,
                doctorName: doctorName
            )
            isLoading = false
            return doctors
        } catch {
            errorMessage = "Failed to search doctors: \(error.localizedDescription)"
            isLoading = false
            return []
        }
    }
}
