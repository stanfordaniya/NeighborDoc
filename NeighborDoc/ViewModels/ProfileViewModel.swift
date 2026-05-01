import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var isDoctorToggle: Bool = false
    @Published var myDoctor: Doctor?
    
    private let directoryStore = DirectoryStore.shared
    private let appViewModel: AppViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        
        // Listen for changes in user's doctor status
        appViewModel.$user
            .sink { [weak self] user in
                if let user = user {
                    self?.isDoctorToggle = user.isDoctor
                    // Only load doctor if myDoctorId changed to avoid unnecessary reloads
                    if let doctorId = user.myDoctorId, self?.myDoctor?.id != doctorId {
                        self?.loadMyDoctor()
                    } else if user.myDoctorId == nil {
                        self?.myDoctor = nil
                    }
                } else {
                    self?.isDoctorToggle = false
                    self?.myDoctor = nil
                }
            }
            .store(in: &cancellables)
        
        // Initial load
        if let user = appViewModel.user {
            isDoctorToggle = user.isDoctor
            loadMyDoctor()
        }
    }
    
    func loadMyDoctor() {
        guard let user = appViewModel.user,
              let doctorId = user.myDoctorId else {
            myDoctor = nil
            return
        }
        myDoctor = directoryStore.doctor(id: doctorId)
    }
    
    func submitDoctorForm(_ doctor: Doctor) {
        guard let user = appViewModel.user else { return }
        
        // Set the owner UID
        var updatedDoctor = doctor
        updatedDoctor.ownerUid = user.uid
        // isActive is already set correctly in the doctor object from the form
        
        // Upsert the doctor
        directoryStore.upsertCustomDoctor(updatedDoctor)
        
        // Update user
        var updatedUser = user
        updatedUser.isDoctor = true
        updatedUser.myDoctorId = doctor.id
        appViewModel.updateUser(updatedUser)
        
        // Update local state
        myDoctor = updatedDoctor
    }
    
    func clearPendingToggle() {
        // This will be called when the doctor form is successfully submitted
        // The toggle state will be managed by the user's isDoctor status
    }
    
    func toggleDoctorStatus() {
        if isDoctorToggle {
            // Turning ON - if no doctor profile, will navigate to form
            if appViewModel.user?.myDoctorId == nil {
                // Will be handled by the view navigation
                return
            } else {
                // If doctor profile exists, make sure it's active
                if let doctorId = appViewModel.user?.myDoctorId {
                    directoryStore.setActive(doctorId, active: true)
                    // Update local state without reloading
                    if var doctor = myDoctor {
                        doctor.isActive = true
                        myDoctor = doctor
                    }
                }
            }
        } else {
            // Turning OFF - set doctor as inactive
            if let doctorId = appViewModel.user?.myDoctorId {
                directoryStore.setActive(doctorId, active: false)
                // Update local state without reloading
                if var doctor = myDoctor {
                    doctor.isActive = false
                    myDoctor = doctor
                }
            }
            
            // Update user
            guard let user = appViewModel.user else { return }
            var updatedUser = user
            updatedUser.isDoctor = false
            appViewModel.updateUser(updatedUser)
        }
    }
}
