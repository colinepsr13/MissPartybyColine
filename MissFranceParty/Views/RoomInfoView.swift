import SwiftUI
import UIKit

/// Onglet "Salon" : code d'invitation, participantes, réglages de l'organisatrice.
struct RoomInfoView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var store: RoomStore
    var onLeave: () -> Void

    @State private var showRename = false
    @State private var newName = ""
    @State private var confirmLeave = false
    @State private var copied = false

    private var isHost: Bool { store.isHost(session.userId) }

    var body: some View {
        List {
            if let room = store.room {
                Section {
                    inviteCard(room)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                if isHost {
                    Section("Organisatrice") {
                        Button {
                            newName = room.name
                            showRename = true
                        } label: {
                            Label("Renommer le salon", systemImage: "pencil")
                        }

                        Picker(selection: Binding(
                            get: { room.showPhase },
                            set: { store.setPhase($0) }
                        )) {
                            ForEach(ShowPhase.allCases) { phase in
                                Text("\(phase.emoji) \(phase.title)").tag(phase)
                            }
                        } label: {
                            Label("Étape de l'émission", systemImage: "tv")
                        }
                    }
                    .listRowBackground(Theme.card)
                } else {
                    Section("Émission") {
                        Label("\(room.showPhase.emoji) \(room.showPhase.title)", systemImage: "tv")
                    }
                    .listRowBackground(Theme.card)
                }

                Section("Participantes (\(store.members.count))") {
                    ForEach(store.members) { member in
                        memberRow(member, room: room)
                    }
                }
                .listRowBackground(Theme.card)

                Section {
                    Button(role: .destructive) { confirmLeave = true } label: {
                        Label("Quitter le salon", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                .listRowBackground(Theme.card)
            } else {
                ProgressView().frame(maxWidth: .infinity).listRowBackground(Color.clear)
            }
        }
        .themedBackground()
        .alert("Renommer le salon", isPresented: $showRename) {
            TextField("Nom du salon", text: $newName)
            Button("Annuler", role: .cancel) {}
            Button("Enregistrer") { store.rename(to: newName) }
        }
        .confirmationDialog("Quitter ce salon ?", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("Quitter", role: .destructive, action: leave)
        } message: {
            Text("Tu pourras le rejoindre à nouveau avec son code.")
        }
    }

    private func inviteCard(_ room: Room) -> some View {
        VStack(spacing: 14) {
            Text("Code d'invitation")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Text(room.code)
                .font(.system(size: 44, weight: .heavy, design: .monospaced))
                .kerning(6)
                .foregroundStyle(Theme.goldGradient)
                .textSelection(.enabled)

            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = room.code
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Label(copied ? "Copié !" : "Copier", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(OutlineButtonStyle())

                ShareLink(item: inviteMessage(room)) {
                    Label("Inviter", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(GoldButtonStyle())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22))
        .padding(.vertical, 8)
    }

    private func memberRow(_ member: Member, room: Room) -> some View {
        let memberId = member.id ?? ""
        let rated = store.ratedCount(userId: memberId)
        return HStack(spacing: 12) {
            Text(String(member.name.prefix(1)).uppercased())
                .font(.headline)
                .foregroundStyle(Theme.navy)
                .frame(width: 36, height: 36)
                .background(Theme.goldGradient, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name).font(.body.weight(.semibold))
                    if memberId == session.userId { Text("(moi)").font(.caption).foregroundStyle(.white.opacity(0.6)) }
                    if memberId == room.hostId { Text("👑").font(.caption) }
                }
                Text("\(rated)/\(store.candidates.count) Miss notées")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private func inviteMessage(_ room: Room) -> String {
        "👑 Rejoins mon salon « \(room.name) » sur Miss Party 2027 pour noter les Miss ensemble ! Code : \(room.code)"
    }

    private func leave() {
        guard let userId = session.userId else { return }
        let roomId = store.roomId
        Task {
            do {
                store.stop()
                try await RoomRepository.leaveRoom(roomId: roomId, userId: userId)
                onLeave()
            } catch {
                store.errorMessage = error.localizedDescription
                store.start()
            }
        }
    }
}
