import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Text("Last Updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        SectionView(
                            title: "Information We Collect",
                            content: """
                            NeighborDoc collects the following information:
                            
                            • Your saved doctor preferences (stored locally on your device)
                            • Doctor profile information you create (if you're a doctor)
                            • Your search preferences (stored locally)
                            
                            All data is stored locally on your device using iOS UserDefaults. No personal information is transmitted to external servers.
                            """
                        )
                        
                        SectionView(
                            title: "How We Use Your Information",
                            content: """
                            We use your information to:
                            
                            • Save your favorite doctors for quick access
                            • Remember your search preferences
                            • Display your doctor profile in search results (if you choose to be visible)
                            
                            Your data remains on your device and is not shared with third parties.
                            """
                        )
                        
                        SectionView(
                            title: "Data Storage",
                            content: """
                            All data is stored locally on your iOS device using Apple's UserDefaults system. This means:
                            
                            • Your data never leaves your device
                            • No external servers or databases are used
                            • Data is automatically backed up with your device's iCloud backup (if enabled)
                            """
                        )
                        
                        SectionView(
                            title: "Sign in with Apple",
                            content: """
                            If you choose to sign in with Apple, we only receive:
                            
                            • A unique identifier
                            • Your display name (if you choose to share it)
                            
                            We do not receive your email address or any other personal information from Apple.
                            """
                        )
                        
                        SectionView(
                            title: "Your Rights",
                            content: """
                            You have the right to:
                            
                            • Delete all your data by deleting the app
                            • Clear your saved doctors at any time
                            • Remove your doctor profile from search results
                            • Use the app without creating an account (Guest mode)
                            """
                        )
                        
                        SectionView(
                            title: "Contact Us",
                            content: """
                            If you have questions about this privacy policy, please contact us through the App Store.
                            
                            This app is designed to help you find doctors in your community. It is not intended for medical advice, diagnosis, or treatment.
                            """
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.accentColor)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
