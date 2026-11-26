import SwiftUI

struct RoomView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var store: RoomStore
    @State private var tab: Tab = .candidates
    var onLeave: () -> Void

    enum Tab: Hashable { case candidates, ranking, chat, room }

    init(roomId: String, onLeave: @escaping () -> Void) {
        _store = StateObject(wrappedValue: RoomStore(roomId: roomId))
        self.onLeave = onLeave
    }

    var body: some View {
        TabView(selection: $tab) {
            CandidatesView()
                .tabItem { Label("Candidates", systemImage: "star.fill") }
                .tag(Tab.candidates)

            RankingView()
                .tabItem { Label("Classement", systemImage: "trophy.fill") }
                .tag(Tab.ranking)

            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(Tab.chat)

            RoomInfoView(onLeave: onLeave)
                .tabItem { Label("Salon", systemImage: "person.3.fill") }
                .tag(Tab.room)
        }
        .environmentObject(store)
        .navigationTitle(store.room?.name ?? "Salon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.navy, for: .navigationBar, .tabBar)
        .toolbarBackground(.visible, for: .navigationBar, .tabBar)
        .onAppear { store.start() }
        .onDisappear { store.stop() }
        .alert("Oups", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

/// Bandeau qui affiche l'étape en cours de l'émission (choisie par l'organisatrice).
struct PhaseBanner: View {
    @EnvironmentObject private var store: RoomStore

    var body: some View {
        if let room = store.room {
            HStack(spacing: 8) {
                Text(room.showPhase.emoji)
                Text(room.showPhase.title).font(.subheadline.weight(.semibold))
                Spacer()
                Circle().fill(Theme.rose).frame(width: 8, height: 8)
                Text("EN DIRECT").font(.caption2.weight(.heavy)).foregroundStyle(Theme.rose)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.gold.opacity(0.15))
        }
    }
}
