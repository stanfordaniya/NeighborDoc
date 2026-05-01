import Foundation
import AuthenticationServices

struct AppleSignInResult {
    let uid: String
    let displayName: String?
    let email: String?
    let identityToken: String?
    let authorizationCode: String?
}

enum AuthenticationError: LocalizedError {
    case signInCancelled
    case invalidCredentials
    case networkError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .signInCancelled:
            return "Sign in was cancelled"
        case .invalidCredentials:
            return "Invalid credentials received"
        case .networkError:
            return "Network error occurred"
        case .unknownError(let message):
            return message
        }
    }
}

class AppleSignInService: NSObject, ObservableObject {
    @Published var isSigningIn = false
    @Published var signInResult: AppleSignInResult?
    @Published var errorMessage: String?
    @Published var isAvailable = true
    
    private let appleIDProvider = ASAuthorizationAppleIDProvider()
    
    override init() {
        super.init()
        checkAppleSignInAvailability()
    }
    
    func signInWithApple() {
        guard isAvailable else {
            errorMessage = "Sign in with Apple is not available on this device"
            return
        }
        
        isSigningIn = true
        errorMessage = nil
        
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func checkAppleSignInAvailability() {
        // Check if Apple Sign In is available
        isAvailable = true // For now, assume it's available
    }
    
    func checkCredentialState(for userID: String, completion: @escaping (ASAuthorizationAppleIDProvider.CredentialState) -> Void) {
        appleIDProvider.getCredentialState(forUserID: userID) { credentialState, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error checking credential state: \(error.localizedDescription)")
                }
                completion(credentialState)
            }
        }
    }
}

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            DispatchQueue.main.async {
                self.isSigningIn = false
                self.errorMessage = AuthenticationError.invalidCredentials.errorDescription
            }
            return
        }
        
        let userID = appleIDCredential.user
        let displayName = appleIDCredential.fullName?.formatted() ?? "User"
        let email = appleIDCredential.email
        let identityToken = String(data: appleIDCredential.identityToken ?? Data(), encoding: .utf8)
        let authorizationCode = String(data: appleIDCredential.authorizationCode ?? Data(), encoding: .utf8)
        
        DispatchQueue.main.async {
            self.isSigningIn = false
            self.signInResult = AppleSignInResult(
                uid: userID,
                displayName: displayName,
                email: email,
                identityToken: identityToken,
                authorizationCode: authorizationCode
            )
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.isSigningIn = false
            
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    self.errorMessage = AuthenticationError.signInCancelled.errorDescription
                case .failed:
                    self.errorMessage = AuthenticationError.networkError.errorDescription
                case .invalidResponse:
                    self.errorMessage = AuthenticationError.invalidCredentials.errorDescription
                case .notHandled:
                    self.errorMessage = AuthenticationError.unknownError("Sign in was not handled").errorDescription
                case .unknown:
                    self.errorMessage = AuthenticationError.unknownError("Unknown error occurred").errorDescription
                case .notInteractive:
                    self.errorMessage = AuthenticationError.unknownError("Sign in is not interactive").errorDescription
                case .matchedExcludedCredential:
                    self.errorMessage = AuthenticationError.unknownError("Credential is excluded").errorDescription
                case .credentialImport:
                    self.errorMessage = AuthenticationError.unknownError("Credential import error").errorDescription
                case .credentialExport:
                    self.errorMessage = AuthenticationError.unknownError("Credential export error").errorDescription
                @unknown default:
                    self.errorMessage = AuthenticationError.unknownError("Unknown error occurred").errorDescription
                }
            } else {
                // Handle simulator-specific errors
                let errorDescription = error.localizedDescription
                if errorDescription.contains("AKAuthenticationError") || 
                   errorDescription.contains("MCPasscodeManager") ||
                   errorDescription.contains("eligibility.plist") {
                    self.errorMessage = "Apple Sign In is not fully supported in the iOS Simulator. Please test on a physical device for the best experience."
                } else {
                    self.errorMessage = errorDescription
                }
            }
        }
    }
}

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            // Fallback to any available window scene
            if let fallbackScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let fallbackWindow = fallbackScene.windows.first {
                return fallbackWindow
            }
            // Last resort - create a new window
            return UIWindow()
        }
        return window
    }
}
