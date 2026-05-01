import SwiftUI

struct DoctorDetailView: View {
    let doctor: Doctor
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var reviewService = ReviewService.shared
    
    init(doctor: Doctor, appViewModel: AppViewModel) {
        self.doctor = doctor
        self.appViewModel = appViewModel
        self._searchViewModel = StateObject(wrappedValue: SearchViewModel(appViewModel: appViewModel))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .font(.title)
                            .foregroundColor(Theme.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(doctor.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(doctor.specialty)
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Professional Info
                VStack(alignment: .leading, spacing: 16) {
                    Text("PROFESSIONAL INFORMATION")
                        .font(Theme.sectionHeaderFont)
                        .foregroundColor(Theme.sectionHeaderColor)
                        .textCase(.uppercase)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Specialty", value: doctor.specialty)
                        DetailRow(label: "Race/Ethnicity", value: doctor.raceEthnicity)
                    }
                }
                .padding()
                .background(Theme.cardStyle())
                
                // Location & Contact
                VStack(alignment: .leading, spacing: 16) {
                    Text("LOCATION & CONTACT")
                        .font(Theme.sectionHeaderFont)
                        .foregroundColor(Theme.sectionHeaderColor)
                        .textCase(.uppercase)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Location")
                                    .font(.headline)
                                    .frame(width: 120, alignment: .leading)
                                
                                Text("\(doctor.city), \(doctor.state) \(doctor.zipCode)")
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Open Apple Maps with location
                                let query = "\(doctor.city), \(doctor.state) \(doctor.zipCode)"
                                if let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                   let url = URL(string: "http://maps.apple.com/?q=\(encodedQuery)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "map")
                                    Text("Map")
                                }
                                .font(.subheadline)
                                .foregroundColor(Theme.accentColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.pillButtonStyle())
                            }
                        }
                        
                        if let phoneNumber = doctor.phoneNumber, !phoneNumber.isEmpty {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Phone")
                                        .font(.headline)
                                        .frame(width: 120, alignment: .leading)
                                    
                                    Text(phoneNumber)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    if let url = URL(string: "tel:\(phoneNumber)") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone")
                                        Text("Call")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(Theme.accentColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Theme.pillButtonStyle())
                                }
                            }
                        }
                        
                        if let hospitalName = doctor.hospitalName, !hospitalName.isEmpty {
                            DetailRow(label: "Hospital", value: hospitalName)
                        }
                    }
                }
                .padding()
                .background(Theme.cardStyle())
                
                // Medical Disclaimer
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Important Notice")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    Text("This app is for informational purposes only. It is not intended for medical advice, diagnosis, or treatment. Always consult with a qualified healthcare provider for medical concerns.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                // Add bottom spacing to prevent content from being cut off
                Spacer(minLength: 150)
            }
            .padding()
            .padding(.bottom, 100) // Extra bottom padding to ensure content is fully visible
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Track doctor view for review prompt
            reviewService.trackDoctorView(doctor.id)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchViewModel.toggleSave(doctor.id)
                        }
                    }) {
                        Image(systemName: searchViewModel.isSaved(doctor.id) ? "star.fill" : "star")
                            .foregroundColor(searchViewModel.isSaved(doctor.id) ? Theme.accentColor : Color.secondary)
                            .font(.title2)
                    }
                    
                    Menu {
                        if let phoneNumber = doctor.phoneNumber, !phoneNumber.isEmpty {
                            Button(action: {
                                if let url = URL(string: "tel:\(phoneNumber)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Label("Call \(phoneNumber)", systemImage: "phone")
                            }
                        }
                        
                        Button(action: {
                            // Open mailto placeholder
                            if let url = URL(string: "mailto:") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("Send Email", systemImage: "envelope")
                        }
                        
                        Button(action: {
                            // Open Apple Maps with location
                            let query = "\(doctor.city), \(doctor.state) \(doctor.zipCode)"
                            if let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                               let url = URL(string: "http://maps.apple.com/?q=\(encodedQuery)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("View on Map", systemImage: "map")
                        }
                    } label: {
                        Text("Contact")
                            .foregroundColor(Theme.accentColor)
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
