import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var user: UserDoc?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let directoryStore = DirectoryStore.shared
    let persistence = Persistence.shared
    let appleSignInService = AppleSignInService()
    let firestoreService = FirestoreService()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load user from secure persistence
        if let savedUser = persistence.securePersistence.loadUserDoc() {
            self.user = savedUser
            self.isAuthenticated = true
            
            // Load saved doctor IDs
            let savedIds = persistence.loadSavedDoctorIds()
            self.user?.savedDoctorIds = savedIds
            
            // Check session validity
            if !persistence.securePersistence.isSessionValid() {
                signOut()
                return
            }
            
            // Update session timestamp
            persistence.securePersistence.saveSessionTimestamp()
            
            // Check credential state for existing user
            checkCredentialState()
        } else {
            self.user = nil
            self.isAuthenticated = false
        }
        
        // Listen for Apple Sign In results
        appleSignInService.$signInResult
            .compactMap { $0 }
            .sink { [weak self] result in
                self?.handleAppleSignIn(result: result)
            }
            .store(in: &cancellables)
        
        // Listen for sign in errors
        appleSignInService.$errorMessage
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
            }
            .store(in: &cancellables)
        
        // Listen for sign in loading state
        appleSignInService.$isSigningIn
            .sink { [weak self] isSigningIn in
                self?.isLoading = isSigningIn
            }
            .store(in: &cancellables)
    }
    
    func signInWithApple() {
        errorMessage = nil
        appleSignInService.signInWithApple()
    }
    
    func signOut() {
        user = nil
        isAuthenticated = false
        errorMessage = nil
        
        // Clear all persisted data securely
        persistence.securePersistence.clearAllSecureData()
        persistence.saveSavedDoctorIds([])
        persistence.saveCustomDoctors([])
    }
    
    private func handleAppleSignIn(result: AppleSignInResult) {
        let newUser = UserDoc(
            uid: result.uid,
            displayName: result.displayName,
            isDoctor: false,
            myDoctorId: nil,
            savedDoctorIds: []
        )
        
        user = newUser
        isAuthenticated = true
        errorMessage = nil
        
        // Save user data securely and update session
        let saveSuccess = persistence.securePersistence.saveUserDoc(newUser)
        if !saveSuccess {
            print("⚠️ Failed to save user data securely")
        }
        persistence.securePersistence.saveSessionTimestamp()
    }
    
    private func checkCredentialState() {
        guard let user = user else { return }
        
        appleSignInService.checkCredentialState(for: user.uid) { [weak self] credentialState in
            switch credentialState {
            case .authorized:
                // User is still authorized, keep them signed in
                break
            case .revoked, .notFound:
                // User's credentials are no longer valid, sign them out
                self?.signOut()
            case .transferred:
                // User's credentials were transferred, sign them out
                self?.signOut()
            @unknown default:
                break
            }
        }
    }
    
    func updateUser(_ newUser: UserDoc) {
        user = newUser
        let saveSuccess = persistence.securePersistence.saveUserDoc(newUser)
        if !saveSuccess {
            print("⚠️ Failed to save user data securely")
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
