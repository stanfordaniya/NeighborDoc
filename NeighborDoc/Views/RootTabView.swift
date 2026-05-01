import SwiftUI

struct RootTabView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        TabView {
            NavigationStack {
                SearchView(appViewModel: appViewModel)
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                Text("Search")
            }
            
            NavigationStack {
                SavedView(appViewModel: appViewModel)
            }
            .tabItem {
                Image(systemName: "star")
                    .font(.system(size: 16, weight: .medium))
                Text("Saved")
            }
            
            NavigationStack {
                ProfileView(appViewModel: appViewModel)
            }
            .tabItem {
                Image(systemName: "person")
                    .font(.system(size: 16, weight: .medium))
                Text("Profile")
            }
        }
        .accentColor(Theme.accentColor)
    }
}
