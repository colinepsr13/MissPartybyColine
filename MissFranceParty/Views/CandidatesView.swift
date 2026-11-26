import SwiftUI

struct CandidatesView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var store: RoomStore
    @State private var selected: Candidate?
    @State private var hideEliminated = false
    @State private var search = ""

    private var userId: String { session.userId ?? "" }

    private var visibleCandidates: [Candidate] {
        store.candidates.filter { candidate in
            (!hideEliminated || !candidate.eliminated) &&
            (search.isEmpty
             || candidate.region.localizedCaseInsensitiveContains(search)
             || candidate.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            PhaseBanner()
            List {
                Section {
                    progressHeader
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    ForEach(visibleCandidates) { candidate in
                        Button { selected = candidate } label: {
                            CandidateRow(candidate: candidate, userId: userId)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.card)
                    }
                }
            }
            .themedBackground()
        }
        .background(Theme.background.ignoresSafeArea())
        .sheet(item: $selected) { candidate in
            CandidateRatingView(candidateId: candidate.id ?? "")
                .environmentObject(store)
                .environmentObject(session)
        }
    }

    private var progressHeader: some View {
        let rated = store.ratedCount(userId: userId)
        let total = max(store.candidates.count, 1)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tu as noté \(rated)/\(store.candidates.count) Miss")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Toggle("Masquer éliminées", isOn: $hideEliminated)
                    .toggleStyle(.button)
                    .font(.caption)
            }
            ProgressView(value: Double(rated), total: Double(total))
                .tint(Theme.gold)
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.6))
                TextField("Rechercher une région ou un nom", text: $search)
                    .autocorrectionDisabled()
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct CandidateRow: View {
    @EnvironmentObject private var store: RoomStore
    let candidate: Candidate
    let userId: String

    var body: some View {
        let id = candidate.id ?? ""
        let mine = store.overall(candidateId: id, userId: userId)
        let group = store.overall(candidateId: id)

        HStack(spacing: 14) {
            Text("\(candidate.number)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.navy)
                .frame(width: 38, height: 38)
                .background(candidate.crowned ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.goldLight.opacity(candidate.eliminated ? 0.3 : 0.9)), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(candidate.title)
                        .font(.headline)
                        .strikethrough(candidate.eliminated, color: .white.opacity(0.6))
                    if candidate.crowned { Text("👑") }
                }
                if let subtitle = candidate.subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                HStack(spacing: 4) {
                    ForEach(Criterion.allCases) { criterion in
                        let done = store.myScore(userId: userId, candidateId: id, criterion: criterion) != nil
                        Text(criterion.emoji)
                            .font(.caption)
                            .opacity(done ? 1 : 0.25)
                    }
                }
            }
            .opacity(candidate.eliminated ? 0.55 : 1)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let mine {
                    Text(mine.value.scoreText)
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.goldLight)
                    Text("ma note").font(.caption2).foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("À noter").font(.caption.weight(.semibold)).foregroundStyle(Theme.rose)
                }
                if let group {
                    Text("Groupe \(group.value.scoreText)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 4)
        .foregroundStyle(.white)
        .contentShape(Rectangle())
    }
}
