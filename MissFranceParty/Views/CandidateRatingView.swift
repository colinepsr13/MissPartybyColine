import SwiftUI
import UIKit

/// Fiche d'une candidate : on la note sur chaque critère de 1 à 10.
struct CandidateRatingView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var store: RoomStore
    @Environment(\.dismiss) private var dismiss
    let candidateId: String

    @State private var editedName = ""
    /// Candidate affichée après navigation précédente/suivante.
    @State private var overrideId: String?

    private var candidate: Candidate? { store.candidates.first { $0.id == currentId } }
    private var userId: String { session.userId ?? "" }
    private var isHost: Bool { store.isHost(session.userId) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let candidate {
                    VStack(spacing: 20) {
                        header(candidate)

                        ForEach(Criterion.allCases) { criterion in
                            criterionCard(criterion)
                        }

                        if isHost { hostTools(candidate) }
                    }
                    .padding(20)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button { goToNeighbour(offset: -1) } label: { Label("Précédente", systemImage: "chevron.left") }
                        .disabled(neighbourId(offset: -1) == nil)
                    Spacer()
                    Button { goToNeighbour(offset: 1) } label: { Label("Suivante", systemImage: "chevron.right") }
                        .disabled(neighbourId(offset: 1) == nil)
                }
            }
            .onAppear { editedName = candidate?.name ?? "" }
        }
    }

    private func neighbourId(offset: Int) -> String? {
        let list = store.candidates
        guard let index = list.firstIndex(where: { $0.id == currentId }) else { return nil }
        let target = index + offset
        guard list.indices.contains(target) else { return nil }
        return list[target].id
    }

    private var currentId: String { overrideId ?? candidateId }

    private func goToNeighbour(offset: Int) {
        guard let id = neighbourId(offset: offset) else { return }
        overrideId = id
        editedName = store.candidates.first(where: { $0.id == id })?.name ?? ""
    }

    // MARK: - Sous-vues

    private func header(_ candidate: Candidate) -> some View {
        VStack(spacing: 8) {
            Text(candidate.crowned ? "👑" : "✨").font(.system(size: 44))
            Text("N° \(candidate.number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.navy)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Theme.goldGradient, in: Capsule())
            Text(candidate.title)
                .font(.system(.title, design: .serif).weight(.bold))
                .foregroundStyle(Theme.goldGradient)
                .multilineTextAlignment(.center)
            if let subtitle = candidate.subtitle {
                Text(subtitle).foregroundStyle(.white.opacity(0.8))
            }
            if candidate.eliminated {
                Text("Éliminée").font(.caption.weight(.bold)).foregroundStyle(Theme.rose)
            }
            if let mine = store.overall(candidateId: currentId, userId: userId) {
                Text("Ma note générale : \(mine.value.scoreText)/10")
                    .font(.headline)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func criterionCard(_ criterion: Criterion) -> some View {
        let myScore = store.myScore(userId: userId, candidateId: currentId, criterion: criterion)
        let group = store.average(candidateId: currentId, criterion: criterion)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(criterion.emoji)  \(criterion.title)").font(.headline)
                Spacer()
                if let group {
                    Text("Groupe : \(group.value.scoreText) (\(group.count))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            ScorePicker(score: myScore) { newValue in
                store.setScore(newValue, criterion: criterion, candidateId: currentId, userId: userId)
            }
        }
        .card()
    }

    private func hostTools(_ candidate: Candidate) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Réservé à l'organisatrice")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.rose)

            HStack {
                TextField("Prénom Nom de la candidate", text: $editedName)
                    .textInputAutocapitalization(.words)
                    .padding(10)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                Button("Enregistrer") { store.setCandidateName(editedName, candidateId: currentId) }
                    .disabled(editedName == candidate.name)
            }

            Toggle("Éliminée", isOn: Binding(
                get: { candidate.eliminated },
                set: { store.setEliminated($0, candidateId: currentId) }
            ))

            Button {
                store.crown(candidateId: candidate.crowned ? nil : currentId)
            } label: {
                Label(candidate.crowned ? "Retirer la couronne" : "Couronner Miss France 2027",
                      systemImage: "crown.fill")
            }
            .buttonStyle(OutlineButtonStyle())
        }
        .card()
    }
}

/// Sélecteur de note de 1 à 10. Toucher la note déjà choisie l'efface.
struct ScorePicker: View {
    let score: Int?
    let onChange: (Int?) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...10, id: \.self) { value in
                let isSelected = score == value
                let isBelow = (score ?? 0) >= value
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onChange(isSelected ? nil : value)
                } label: {
                    Text("\(value)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .foregroundStyle(isBelow ? Theme.navy : .white.opacity(0.8))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isBelow ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Theme.rose : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
