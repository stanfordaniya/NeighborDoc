import Foundation
import StoreKit
import UIKit

class ReviewService: ObservableObject {
    static let shared = ReviewService()
    
    @Published var hasRequestedReview = false
    private let reviewThreshold = 3 // Trigger after 3 doctor views
    private let persistence = Persistence.shared
    
    private init() {
        loadReviewState()
    }
    
    // MARK: - Review Tracking
    
    func trackDoctorView(_ doctorId: String) {
        var viewedDoctors = getViewedDoctors()
        
        // Only add if not already viewed
        if !viewedDoctors.contains(doctorId) {
            viewedDoctors.append(doctorId)
            saveViewedDoctors(viewedDoctors)
            
            print("📊 Doctor views: \(viewedDoctors.count)/\(reviewThreshold)")
            
            // Check if we should request review
            if viewedDoctors.count >= reviewThreshold && !hasRequestedReview {
                requestAppStoreReview()
            }
        }
    }
    
    func trackDoctorSave(_ doctorId: String) {
        // Also track when doctors are saved as a positive engagement signal
        var savedDoctors = getSavedDoctors()
        
        if !savedDoctors.contains(doctorId) {
            savedDoctors.append(doctorId)
            saveSavedDoctors(savedDoctors)
            
            print("💾 Doctor saves: \(savedDoctors.count)")
            
            // Request review after saving 2 doctors (alternative trigger)
            if savedDoctors.count >= 2 && !hasRequestedReview {
                requestAppStoreReview()
            }
        }
    }
    
    // MARK: - App Store Review Request
    
    private func requestAppStoreReview() {
        guard !hasRequestedReview else { return }
        
        // Check if we're in a good state to request review
        guard shouldRequestReview() else { return }
        
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {
                
                print("⭐ Requesting App Store review...")
                if #available(iOS 18.0, *) {
                    AppStore.requestReview(in: windowScene)
                } else {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
                
                self.hasRequestedReview = true
                self.saveReviewState()
            }
        }
    }
    
    private func shouldRequestReview() -> Bool {
        // Additional checks to ensure good timing
        let viewedCount = getViewedDoctors().count
        let savedCount = getSavedDoctors().count
        
        // Only request if user has engaged meaningfully
        return viewedCount >= reviewThreshold || savedCount >= 2
    }
    
    // MARK: - Persistence
    
    private func getViewedDoctors() -> [String] {
        return persistence.load([String].self, key: "viewedDoctors") ?? []
    }
    
    private func saveViewedDoctors(_ doctors: [String]) {
        persistence.save(doctors, key: "viewedDoctors")
    }
    
    private func getSavedDoctors() -> [String] {
        return persistence.load([String].self, key: "savedDoctorsForReview") ?? []
    }
    
    private func saveSavedDoctors(_ doctors: [String]) {
        persistence.save(doctors, key: "savedDoctorsForReview")
    }
    
    private func loadReviewState() {
        hasRequestedReview = persistence.load(Bool.self, key: "hasRequestedReview") ?? false
    }
    
    private func saveReviewState() {
        persistence.save(hasRequestedReview, key: "hasRequestedReview")
    }
    
    // MARK: - Reset for Testing
    
    func resetReviewState() {
        hasRequestedReview = false
        persistence.save([String](), key: "viewedDoctors")
        persistence.save([String](), key: "savedDoctorsForReview")
        persistence.save(false, key: "hasRequestedReview")
        print("🔄 Review state reset for testing")
    }
    
    // MARK: - Manual Review Request
    
    func requestReviewManually() {
        guard !hasRequestedReview else {
            print("⚠️ Review already requested")
            return
        }
        
        requestAppStoreReview()
    }
    
    // MARK: - Analytics
    
    func getReviewMetrics() -> (viewed: Int, saved: Int, hasRequested: Bool) {
        return (
            viewed: getViewedDoctors().count,
            saved: getSavedDoctors().count,
            hasRequested: hasRequestedReview
        )
    }
}
