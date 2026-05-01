//
//  NeighborDocApp.swift
//  NeighborDoc
//
//  Created by Aniya Stanford on 9/23/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct NeighborDocApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            if appViewModel.isAuthenticated {
                RootTabView(appViewModel: appViewModel)
            } else {
                LoginView(appViewModel: appViewModel)
            }
        }
    }
}
