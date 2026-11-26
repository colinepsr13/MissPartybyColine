import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var home = HomeStore()
    @State private var path: [String] = []
    @State private var showCreate = false
    @State private var showJoin = false
    @State private var showRename = false
    @State private var newName = ""

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    CrownTitle(text: "Miss Party 2027")
                        .padding(.top, 8)
                    Text("Coucou \(session.displayName) 💖")
                        .font(.title3.weight(.semibold))

                    VStack(spacing: 12) {
                        Button { showCreate = true } label: {
                            Label("Créer un salon", systemImage: "sparkles")
                        }
                        .buttonStyle(GoldButtonStyle())

                        Button { showJoin = true } label: {
                            Label("Rejoindre avec un code", systemImage: "person.2.fill")
                        }
                        .buttonStyle(OutlineButtonStyle())
                    }

                    roomsSection
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newName = session.displayName
                        showRename = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .navigationDestination(for: String.self) { roomId in
                RoomView(roomId: roomId, onLeave: { path.removeAll() })
            }
            .sheet(isPresented: $showCreate) {
                CreateRoomSheet { roomId in path = [roomId] }
            }
            .sheet(isPresented: $showJoin) {
                JoinRoomSheet { roomId in path = [roomId] }
            }
            .alert("Ton pseudo", isPresented: $showRename) {
                TextField("Pseudo", text: $newName)
                Button("Annuler", role: .cancel) {}
                Button("Enregistrer") {
                    let trimmed = newName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { session.displayName = String(trimmed.prefix(30)) }
                }
            } message: {
                Text("Il s'affichera pour les nouveaux salons que tu rejoins.")
            }
        }
        .onAppear { if let id = session.userId { home.start(userId: id) } }
    }

    @ViewBuilder
    private var roomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mes salons")
                .font(.headline)
                .foregroundStyle(Theme.goldLight)

            if home.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if home.rooms.isEmpty {
                Text("Aucun salon pour l'instant. Crée le tien et partage le code à tes copines !")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
                    .card()
            } else {
                ForEach(home.rooms) { room in
                    if let id = room.id {
                        NavigationLink(value: id) {
                            RoomRow(room: room, isHost: room.hostId == session.userId)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct RoomRow: View {
    let room: Room
    let isHost: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(room.showPhase.emoji)
                .font(.title)
                .frame(width: 50, height: 50)
                .background(Theme.gold.opacity(0.2), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name).font(.headline)
                Text("\(room.memberIds.count) participante\(room.memberIds.count > 1 ? "s" : "") · code \(room.code)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                if isHost {
                    Text("Organisatrice").font(.caption2.weight(.bold)).foregroundStyle(Theme.rose)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.gold)
        }
        .card()
    }
}

// MARK: - Création / adhésion

struct CreateRoomSheet: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    var onCreated: (String) -> Void

    @State private var name = "Soirée Miss France 2027"
    @State private var isWorking = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Donne un nom à ton salon, puis partage le code à tes copines pour qu'elles te rejoignent.")
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                TextField("Nom du salon", text: $name)
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))

                if let error {
                    Text(error).font(.callout).foregroundStyle(Theme.rose)
                }

                Button {
                    create()
                } label: {
                    if isWorking { ProgressView().tint(Theme.navy) } else { Text("Créer le salon 👑") }
                }
                .buttonStyle(GoldButtonStyle())
                .disabled(isWorking)
                Spacer()
            }
            .padding(24)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Nouveau salon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }

    private func create() {
        guard let userId = session.userId else { return }
        isWorking = true
        error = nil
        Task {
            do {
                let roomId = try await RoomRepository.createRoom(name: name, userId: userId, userName: session.displayName)
                dismiss()
                onCreated(roomId)
            } catch {
                self.error = error.localizedDescription
            }
            isWorking = false
        }
    }
}

struct JoinRoomSheet: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    var onJoined: (String) -> Void

    @State private var code = ""
    @State private var isWorking = false
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Entre le code à 6 caractères que ta copine t'a envoyé.")
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                TextField("ABC123", text: $code)
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
                    .onChange(of: code) { _, newValue in
                        let cleaned = String(RoomRepository.normalize(code: newValue).prefix(RoomRepository.codeLength))
                        if cleaned != newValue { code = cleaned }
                    }

                if let error {
                    Text(error).font(.callout).foregroundStyle(Theme.rose).multilineTextAlignment(.center)
                }

                Button {
                    join()
                } label: {
                    if isWorking { ProgressView().tint(Theme.navy) } else { Text("Rejoindre ✨") }
                }
                .buttonStyle(GoldButtonStyle())
                .disabled(isWorking || code.count != RoomRepository.codeLength)
                Spacer()
            }
            .padding(24)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Rejoindre un salon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }

    private func join() {
        guard let userId = session.userId else { return }
        isWorking = true
        error = nil
        Task {
            do {
                let roomId = try await RoomRepository.joinRoom(code: code, userId: userId, userName: session.displayName)
                dismiss()
                onJoined(roomId)
            } catch {
                self.error = error.localizedDescription
            }
            isWorking = false
        }
    }
}
