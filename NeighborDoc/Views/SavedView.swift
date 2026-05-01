import SwiftUI

struct SavedView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var savedViewModel: SavedViewModel
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self._savedViewModel = StateObject(wrappedValue: SavedViewModel(appViewModel: appViewModel))
    }
    
    var body: some View {
        Group {
            if savedViewModel.savedDoctors.isEmpty {
                VStack(spacing: 24) {
                    // Friendly illustration
                    VStack(spacing: 16) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Theme.accentColor)
                        
                        VStack(spacing: 8) {
                            Text("You haven't saved any doctors yet.")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text("Tap the star on any doctor to save them for easy access.")
                                .font(Theme.emptyStateFont)
                                .foregroundColor(Theme.emptyStateColor)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                }
                .padding()
            } else {
                List {
                    ForEach(savedViewModel.savedDoctors) { doctor in
                        ZStack {
                            NavigationLink(destination: DoctorDetailView(doctor: doctor, appViewModel: appViewModel)) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            SavedDoctorCard(doctor: doctor, savedViewModel: savedViewModel)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 1.05))
                        ))
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let doctor = savedViewModel.savedDoctors[index]
                            savedViewModel.unsave(doctor.id)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .animation(.easeInOut(duration: 0.2), value: savedViewModel.savedDoctors.count)
            }
        }
        .navigationTitle("Saved Doctors")
    }
}

struct SavedDoctorCard: View {
    let doctor: Doctor
    @ObservedObject var savedViewModel: SavedViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Doctor icon
            Image(systemName: "stethoscope")
                .font(.title2)
                .foregroundColor(Theme.accentColor)
                .frame(width: 32, height: 32)
                .background(Theme.accentColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(doctor.name)
                    .font(Theme.doctorNameFont)
                    .foregroundColor(Theme.doctorNameColor)
                
                Text(doctor.specialty)
                    .font(Theme.specialtyFont)
                    .foregroundColor(Theme.specialtyColor)
                
                Text("\(doctor.raceEthnicity) • \(doctor.city), \(doctor.state)")
                    .font(Theme.locationFont)
                    .foregroundColor(Theme.locationColor)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    savedViewModel.unsave(doctor.id)
                }
            }) {
                Image(systemName: "star.fill")
                    .foregroundColor(Theme.accentColor)
                    .font(.title2)
                    .scaleEffect(1.1)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, Theme.listItemPadding)
        .padding(.horizontal, Theme.cardPadding)
        .background(Theme.cardStyle())
        .frame(minHeight: 60)
    }
}
