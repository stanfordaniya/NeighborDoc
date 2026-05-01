import SwiftUI

struct SearchView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var searchViewModel: SearchViewModel
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self._searchViewModel = StateObject(wrappedValue: SearchViewModel(appViewModel: appViewModel))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            VStack(spacing: 12) {
                // Search fields
                VStack(spacing: 8) {
                    TextField("Doctor name", text: $searchViewModel.doctorName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("City or ZIP", text: $searchViewModel.cityOrZip)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Filter pickers
                HStack {
                    Picker("Specialty", selection: $searchViewModel.specialty) {
                        Text("All Specialties").tag("")
                        ForEach(Constants.specialties, id: \.self) { specialty in
                            Text(specialty).tag(specialty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.dropdownBackground)
                    .cornerRadius(Theme.cornerRadius)
                    
                    Picker("Race/Ethnicity", selection: $searchViewModel.race) {
                        Text("All").tag("")
                        ForEach(Constants.raceEthnicities, id: \.self) { race in
                            Text(race).tag(race)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.dropdownBackground)
                    .cornerRadius(Theme.cornerRadius)
                }
                
                // Clear all filters button
                if !searchViewModel.doctorName.isEmpty || !searchViewModel.cityOrZip.isEmpty || !searchViewModel.specialty.isEmpty || !searchViewModel.race.isEmpty {
                    Button("Clear All Filters") {
                        searchViewModel.clearFilters()
                    }
                    .foregroundColor(Theme.accentColor)
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Results count
            if !searchViewModel.results.isEmpty {
                HStack {
                    Text("\(searchViewModel.results.count) doctor\(searchViewModel.results.count == 1 ? "" : "s") found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // Results
            if searchViewModel.results.isEmpty {
                EmptyStateView(
                    title: "No doctors match your filters.",
                    subtitle: "Try adjusting your search.",
                    systemImage: "magnifyingglass"
                )
            } else {
                List(searchViewModel.results) { doctor in
                    ZStack {
                        NavigationLink(destination: DoctorDetailView(doctor: doctor, appViewModel: appViewModel)) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        DoctorCard(doctor: doctor, searchViewModel: searchViewModel)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.15), value: searchViewModel.results.count)
            }
        }
        .navigationTitle("Search")
        .onAppear {
            searchViewModel.applyFilters()
        }
    }
}
