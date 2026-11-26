import SwiftUI
import FirebaseCore

@main
struct MissFrancePartyApp: App {
    @StateObject private var session = SessionStore()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
        }
    }
}
