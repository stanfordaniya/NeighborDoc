import SwiftUI

struct DoctorCard: View {
    let doctor: Doctor
    @ObservedObject var searchViewModel: SearchViewModel
    
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
                    searchViewModel.toggleSave(doctor.id)
                }
            }) {
                Image(systemName: searchViewModel.isSaved(doctor.id) ? "star.fill" : "star")
                    .foregroundColor(searchViewModel.isSaved(doctor.id) ? Theme.accentColor : Color.secondary)
                    .font(.title2)
                    .scaleEffect(searchViewModel.isSaved(doctor.id) ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: searchViewModel.isSaved(doctor.id))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, Theme.listItemPadding)
        .padding(.horizontal, Theme.cardPadding)
        .background(Theme.cardStyle())
        .frame(minHeight: 60)
    }
}
