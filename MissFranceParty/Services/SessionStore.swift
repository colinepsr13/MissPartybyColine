import Foundation
import FirebaseAuth

/// Gère l'utilisatrice courante : connexion anonyme Firebase + pseudo choisi.
/// Les callbacks Firebase Auth arrivent sur le thread principal.
final class SessionStore: ObservableObject {
    @Published private(set) var userId: String?
    @Published private(set) var isSigningIn = false
    @Published var authError: String?
    @Published var displayName: String {
        didSet { UserDefaults.standard.set(displayName, forKey: Self.nameKey) }
    }

    private static let nameKey = "displayName"

    init() {
        displayName = UserDefaults.standard.string(forKey: Self.nameKey) ?? ""
        userId = Auth.auth().currentUser?.uid
    }

    var hasName: Bool { !displayName.trimmingCharacters(in: .whitespaces).isEmpty }

    func signInIfNeeded() {
        if let user = Auth.auth().currentUser {
            userId = user.uid
            return
        }
        guard !isSigningIn else { return }
        isSigningIn = true
        authError = nil
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self else { return }
            self.isSigningIn = false
            if let user = result?.user {
                self.userId = user.uid
            } else {
                self.authError = "Connexion impossible : \(error?.localizedDescription ?? "erreur inconnue")"
            }
        }
    }
}
