import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var doctorName: String = ""
    @Published var cityOrZip: String = ""
    @Published var specialty: String = ""
    @Published var race: String = ""
    @Published var results: [Doctor] = []
    
    private let directoryStore = DirectoryStore.shared
    private let appViewModel: AppViewModel
    private let reviewService = ReviewService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        
        // Listen for filter changes and apply them
        Publishers.CombineLatest4($doctorName, $cityOrZip, $specialty, $race)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Listen for changes in user's saved doctor IDs to update UI immediately
        appViewModel.$user
            .map { $0?.savedDoctorIds ?? [] }
            .sink { [weak self] _ in
                // Trigger UI update when saved doctor IDs change
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func applyFilters() {
        let validator = InputValidator.shared
        
        let doctorNameFilter = doctorName.isEmpty ? nil : validator.sanitizeSearchQuery(doctorName)
        let cityOrZipFilter = cityOrZip.isEmpty ? nil : validator.sanitizeSearchQuery(cityOrZip)
        let specialtyFilter = specialty.isEmpty ? nil : validator.sanitizeString(specialty)
        let raceFilter = race.isEmpty ? nil : validator.sanitizeString(race)
        
        results = directoryStore.search(
            doctorName: doctorNameFilter,
            cityOrZip: cityOrZipFilter,
            specialty: specialtyFilter,
            race: raceFilter
        )
    }
    
    func clearFilters() {
        doctorName = ""
        cityOrZip = ""
        specialty = ""
        race = ""
    }
    
    func toggleSave(_ doctorId: String) {
        guard let user = appViewModel.user else { return }
        
        var savedIds = user.savedDoctorIds
        
        if savedIds.contains(doctorId) {
            savedIds.removeAll { $0 == doctorId }
        } else {
            savedIds.append(doctorId)
            // Track doctor save for review prompt
            reviewService.trackDoctorSave(doctorId)
        }
        
        var updatedUser = user
        updatedUser.savedDoctorIds = savedIds
        appViewModel.updateUser(updatedUser)
        
        // Update persistence
        appViewModel.persistence.saveSavedDoctorIds(savedIds)
    }
    
    func isSaved(_ doctorId: String) -> Bool {
        return appViewModel.user?.savedDoctorIds.contains(doctorId) ?? false
    }
}
