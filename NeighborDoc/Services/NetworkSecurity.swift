import Foundation
import Network

class NetworkSecurity {
    static let shared = NetworkSecurity()
    
    private let rateLimiter = RateLimiter()
    private let networkMonitor = NWPathMonitor()
    private var isNetworkSecure = true
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkSecure = path.status == .satisfied && path.usesInterfaceType(.wifi)
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    // MARK: - Rate Limiting
    
    func canMakeRequest() -> Bool {
        return rateLimiter.canMakeRequest()
    }
    
    func recordRequest() {
        rateLimiter.recordRequest()
    }
    
    // MARK: - Request Validation
    
    func validateRequest(_ request: URLRequest) -> Bool {
        // Check if network is secure
        guard isNetworkSecure else {
            print("⚠️ Network security warning: Insecure connection detected")
            return false
        }
        
        // Check rate limiting
        guard canMakeRequest() else {
            print("⚠️ Rate limit exceeded")
            return false
        }
        
        // Validate URL
        guard let url = request.url,
              url.scheme == "https",
              url.host?.contains("localhost") != true else {
            print("⚠️ Invalid URL detected")
            return false
        }
        
        return true
    }
    
    // MARK: - Certificate Pinning (for custom endpoints)
    
    func validateCertificate(_ serverTrust: SecTrust, host: String) -> Bool {
        // Implement certificate pinning for critical endpoints
        // This is a simplified version - implement proper certificate validation
        return true
    }
}

// MARK: - Rate Limiter

class RateLimiter {
    private var requestTimes: [Date] = []
    private let maxRequests = 100 // per hour
    private let timeWindow: TimeInterval = 3600 // 1 hour
    
    func canMakeRequest() -> Bool {
        let now = Date()
        let cutoffTime = now.addingTimeInterval(-timeWindow)
        
        // Remove old requests
        requestTimes.removeAll { $0 < cutoffTime }
        
        return requestTimes.count < maxRequests
    }
    
    func recordRequest() {
        requestTimes.append(Date())
    }
}
