import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        Group {
            if session.userId == nil {
                connectingView
            } else if !session.hasName {
                OnboardingView()
            } else {
                HomeView()
            }
        }
        .onAppear { session.signInIfNeeded() }
    }

    private var connectingView: some View {
        VStack(spacing: 24) {
            CrownTitle(text: "Miss Party 2027")
            if let error = session.authError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                Button("Réessayer") { session.signInIfNeeded() }
                    .buttonStyle(GoldButtonStyle())
                    .padding(.horizontal, 40)
            } else {
                ProgressView().tint(Theme.gold)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            CrownTitle(text: "Miss Party 2027")
            Text("Regarde l'élection de Miss France avec tes copines, même à distance, et notez vos Miss préférées !")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))

            VStack(alignment: .leading, spacing: 8) {
                Text("Ton pseudo").font(.subheadline).foregroundStyle(Theme.goldLight)
                TextField("Ex : Coline", text: $name)
                    .textInputAutocapitalization(.words)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            }

            Button("C'est parti ✨", action: save)
                .buttonStyle(GoldButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            Spacer()
        }
        .padding(24)
        .background(Theme.background.ignoresSafeArea())
        .onAppear { focused = true }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        session.displayName = String(trimmed.prefix(30))
    }
}
