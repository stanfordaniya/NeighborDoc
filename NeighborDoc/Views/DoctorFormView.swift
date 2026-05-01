import SwiftUI

struct DoctorFormView: View {
    @ObservedObject var appViewModel: AppViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    let existingDoctor: Doctor?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var specialty: String = ""
    @State private var raceEthnicity: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var phoneNumber: String = ""
    @State private var hospitalName: String = ""
    @State private var showInDirectory: Bool = true
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(appViewModel: AppViewModel, profileViewModel: ProfileViewModel, existingDoctor: Doctor?) {
        self.appViewModel = appViewModel
        self.profileViewModel = profileViewModel
        self.existingDoctor = existingDoctor
        
        // Initialize form fields with existing data
        if let doctor = existingDoctor {
            _name = State(initialValue: doctor.name)
            _specialty = State(initialValue: doctor.specialty)
            _raceEthnicity = State(initialValue: doctor.raceEthnicity)
            _city = State(initialValue: doctor.city)
            _state = State(initialValue: doctor.state)
            _zipCode = State(initialValue: doctor.zipCode)
            _phoneNumber = State(initialValue: doctor.phoneNumber ?? "")
            _hospitalName = State(initialValue: doctor.hospitalName ?? "")
            _showInDirectory = State(initialValue: doctor.isActive != false)
        }
    }
    
    var isFormValid: Bool {
        let validator = InputValidator.shared
        
        return !name.isEmpty &&
        !specialty.isEmpty &&
        !raceEthnicity.isEmpty &&
        !city.isEmpty &&
        validator.isValidName(name) &&
        validator.isValidSpecialty(specialty) &&
        validator.isValidRaceEthnicity(raceEthnicity) &&
        validator.isValidState(state) &&
        validator.isValidZipCode(zipCode) &&
        (phoneNumber.isEmpty || validator.isValidPhoneNumber(phoneNumber)) &&
        !validator.containsXSSPatterns(name) &&
        !validator.containsSQLInjectionPatterns(name)
    }
    
    var body: some View {
        Form {
                Section("Personal Information") {
                    TextField("Name", text: $name)
                    Picker("Specialty", selection: $specialty) {
                        Text("Select Specialty").tag("")
                        ForEach(Constants.specialties, id: \.self) { specialty in
                            Text(specialty).tag(specialty)
                        }
                    }
                    Picker("Race/Ethnicity", selection: $raceEthnicity) {
                        Text("Select Race/Ethnicity").tag("")
                        ForEach(Constants.raceEthnicities, id: \.self) { race in
                            Text(race).tag(race)
                        }
                    }
                }
                
                Section("Location") {
                    TextField("City", text: $city)
                    TextField("State (2 letters)", text: $state)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: state) { _, newValue in
                            state = String(newValue.prefix(2)).uppercased()
                        }
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                        .onChange(of: zipCode) { _, newValue in
                            zipCode = String(newValue.prefix(5))
                        }
                }
                
                Section("Contact Information") {
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Hospital Name", text: $hospitalName)
                }
                
                Section {
                    Toggle("Show my profile in directory", isOn: $showInDirectory)
                }
            }
            .navigationTitle(existingDoctor == nil ? "Create Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDoctor()
                    }
                    .disabled(!isFormValid)
                }
        }
        .onAppear {
            // Form is already initialized with existing data in init
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    
    private func saveDoctor() {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields correctly."
            showingAlert = true
            return
        }
        
        let doctor = Doctor(
            id: existingDoctor?.id ?? UUID().uuidString,
            name: name,
            specialty: specialty,
            raceEthnicity: raceEthnicity,
            city: city,
            state: state,
            zipCode: zipCode,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            hospitalName: hospitalName.isEmpty ? nil : hospitalName,
            ownerUid: appViewModel.user?.uid,
            isActive: showInDirectory
        )
        
        profileViewModel.submitDoctorForm(doctor)
        dismiss()
    }
}
