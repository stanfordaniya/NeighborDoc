import SwiftUI
import CryptoKit

struct ProfileView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @State private var showingDoctorForm = false
    @State private var pendingDoctorToggle = false // Track if toggle is pending form completion
    @State private var showingDeleteAccountAlert = false
    @State private var showingDeleteConfirmation = false
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel(appViewModel: appViewModel))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Account Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("ACCOUNT")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.accentColor)
                        
                        Text(appViewModel.user?.displayName ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let uid = appViewModel.user?.uid {
                            Text("ID: \(secureUserID(uid))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.cardStyle())
                }
                
                // Directory Settings Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("DIRECTORY SETTINGS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("I am a doctor", isOn: $profileViewModel.isDoctorToggle)
                                .font(.headline)
                                .onChange(of: profileViewModel.isDoctorToggle) { _, newValue in
                                    if newValue && appViewModel.user?.myDoctorId == nil {
                                        // User wants to become a doctor but has no profile yet
                                        // Set pending state and show the form
                                        pendingDoctorToggle = true
                                        showingDoctorForm = true
                                    } else {
                                        // User has a profile or is turning off - handle normally
                                        pendingDoctorToggle = false
                                        profileViewModel.toggleDoctorStatus()
                                    }
                                }
                            
                            Text("Enable this to create a doctor profile and join the public directory.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if profileViewModel.isDoctorToggle && appViewModel.user?.myDoctorId != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Button("Manage my doctor profile") {
                                    showingDoctorForm = true
                                }
                                .foregroundColor(Theme.accentColor)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                
                                Toggle("Show my profile in directory", isOn: Binding(
                                    get: { profileViewModel.myDoctor?.isActive != false },
                                    set: { newValue in
                                        if let doctorId = appViewModel.user?.myDoctorId {
                                            DirectoryStore.shared.setActive(doctorId, active: newValue)
                                            // Update local state without reloading from store
                                            if var doctor = profileViewModel.myDoctor {
                                                doctor.isActive = newValue
                                                profileViewModel.myDoctor = doctor
                                            }
                                        }
                                    }
                                ))
                                .font(.subheadline)
                                
                                Text("When enabled, your profile will appear in search results.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Theme.cardStyle())
                }
                
                
                // Account Actions Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("ACCOUNT ACTIONS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    VStack(spacing: 12) {
                        // Sign Out Button
                        Button(action: {
                            appViewModel.signOut()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .foregroundColor(.orange)
                                Text("Sign Out")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Delete Account Button
                        Button(action: {
                            showingDeleteAccountAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Delete Account")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("Profile")
        .onChange(of: appViewModel.user?.myDoctorId) { _, newDoctorId in
            // If a doctor profile was successfully created, clear the pending state
            if newDoctorId != nil && pendingDoctorToggle {
                pendingDoctorToggle = false
            }
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                showingDeleteConfirmation = true
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data, including any saved doctors and doctor profiles.")
        }
        .alert("Confirm Account Deletion", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Forever", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .sheet(isPresented: $showingDoctorForm, onDismiss: {
            // If the form was dismissed without saving and we were in pending state,
            // revert the toggle back to OFF
            if pendingDoctorToggle && appViewModel.user?.myDoctorId == nil {
                profileViewModel.isDoctorToggle = false
                pendingDoctorToggle = false
            }
        }) {
            NavigationStack {
                DoctorFormView(
                    appViewModel: appViewModel,
                    profileViewModel: profileViewModel,
                    existingDoctor: profileViewModel.myDoctor
                )
            }
        }
    }
    
    // MARK: - Account Deletion
    private func deleteAccount() {
        guard let user = appViewModel.user else { 
            print("❌ No user found to delete")
            return 
        }
        
        let userId = user.uid
        let doctorId = user.myDoctorId
        
        print("🗑️ Starting account deletion for user: \(userId)")
        print("🗑️ User has doctor profile: \(doctorId != nil)")
        
        // Delete user document from Firestore
        appViewModel.firestoreService.deleteUser(userId) { userDeleteSuccess in
            DispatchQueue.main.async {
                if userDeleteSuccess {
                    print("✅ User document deleted from Firestore")
                } else {
                    print("⚠️ Failed to delete user document from Firestore")
                }
                
                // Delete doctor profile if user is a doctor
                if let doctorId = doctorId {
                    print("🗑️ Deleting doctor profile: \(doctorId)")
                    appViewModel.firestoreService.deleteDoctor(doctorId) { doctorDeleteSuccess in
                        DispatchQueue.main.async {
                            if doctorDeleteSuccess {
                                print("✅ Doctor profile deleted from Firestore")
                            } else {
                                print("⚠️ Failed to delete doctor profile from Firestore")
                            }
                            
                            // Complete the deletion process
                            completeAccountDeletion()
                        }
                    }
                } else {
                    // No doctor profile to delete, complete the process
                    print("🗑️ No doctor profile to delete")
                    completeAccountDeletion()
                }
            }
        }
    }
    
    private func completeAccountDeletion() {
        // Clear all local data (this is the permanent deletion)
        appViewModel.persistence.securePersistence.clearAllSecureData()
        appViewModel.persistence.saveSavedDoctorIds([])
        appViewModel.persistence.saveCustomDoctors([])
        
        // Clear user state (this signs them out and removes all app data)
        appViewModel.user = nil
        appViewModel.isAuthenticated = false
        appViewModel.errorMessage = nil
        
        print("✅ Account permanently deleted - all data removed")
        print("✅ User document deleted from Firestore")
        print("✅ All local data cleared from keychain")
        print("✅ User signed out and app state reset")
    }
    
    // MARK: - Secure User ID Helper
    private func secureUserID(_ uid: String) -> String {
        // Create a hash of the User ID for safe display
        let data = Data(uid.utf8)
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Return first 8 characters of hash for display (safe and readable)
        return String(hashString.prefix(8))
    }
}
