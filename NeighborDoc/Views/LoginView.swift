import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.accentColor)
                
                Text("NeighborDoc")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Find doctors in your community")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Join NeighborDoc to discover and save doctors in your community")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                // Error message
                if let errorMessage = appViewModel.errorMessage {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Sign In Error")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            appViewModel.clearError()
                        }
                        .font(.subheadline)
                        .foregroundColor(Theme.accentColor)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Sign in with Apple button
                if appViewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Signing in...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 50)
                } else {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                // Handle successful authorization
                                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                    let userID = appleIDCredential.user
                                    let displayName = appleIDCredential.fullName?.formatted() ?? "User"
                                    let email = appleIDCredential.email
                                    
                                    // Create the result and handle it
                                    let signInResult = AppleSignInResult(
                                        uid: userID,
                                        displayName: displayName,
                                        email: email,
                                        identityToken: String(data: appleIDCredential.identityToken ?? Data(), encoding: .utf8),
                                        authorizationCode: String(data: appleIDCredential.authorizationCode ?? Data(), encoding: .utf8)
                                    )
                                    
                                    // Update the service with the result
                                    appViewModel.appleSignInService.signInResult = signInResult
                                }
                            case .failure(let error):
                                // Handle error
                                appViewModel.appleSignInService.errorMessage = error.localizedDescription
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Privacy notice
                Text("By signing in, you agree to our Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
