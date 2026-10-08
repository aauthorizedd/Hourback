import AuthenticationServices
import SwiftUI

struct AccountView: View {
    var model: AppModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HourBackScreen {
            if model.isSignedIn {
                Text(model.displayName ?? "Signed in")
                    .font(Typography.body)
                OutlineButton(title: "Sign out") {
                    model.signOut()
                }
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName]
                } onCompletion: { result in
                    handle(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
        }
        .navigationTitle("Account")
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            model.alertMessage = "Sign in with Apple didn't finish."
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            let name = credential.fullName.flatMap { components -> String? in
                let formatted = PersonNameComponentsFormatter().string(from: components)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return formatted.isEmpty ? nil : formatted
            }
            model.signIn(userID: credential.user, name: name)
        }
    }
}
