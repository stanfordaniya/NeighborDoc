import Foundation
import Combine

class SavedViewModel: ObservableObject {
    @Published var savedDoctors: [Doctor] = []
    
    private let directoryStore = DirectoryStore.shared
    private let appViewModel: AppViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        
        // Listen for changes in saved doctor IDs
        appViewModel.$user
            .map { $0?.savedDoctorIds ?? [] }
            .sink { [weak self] savedIds in
                self?.updateSavedDoctors(savedIds: savedIds)
            }
            .store(in: &cancellables)
        
        // Initial load
        updateSavedDoctors(savedIds: appViewModel.user?.savedDoctorIds ?? [])
    }
    
    private func updateSavedDoctors(savedIds: [String]) {
        savedDoctors = savedIds.compactMap { id in
            directoryStore.doctor(id: id)
        }
    }
    
    func unsave(_ doctorId: String) {
        guard let user = appViewModel.user else { return }
        
        var savedIds = user.savedDoctorIds
        savedIds.removeAll { $0 == doctorId }
        
        var updatedUser = user
        updatedUser.savedDoctorIds = savedIds
        appViewModel.updateUser(updatedUser)
        
        // Update persistence
        appViewModel.persistence.saveSavedDoctorIds(savedIds)
    }
}
