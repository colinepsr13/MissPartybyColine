import SwiftUI

struct RankingView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var store: RoomStore

    enum Scope: String, CaseIterable, Identifiable {
        case group = "Le groupe"
        case me = "Moi"
        var id: String { rawValue }
    }

    @State private var scope: Scope = .group
    /// `nil` = classement général.
    @State private var criterion: Criterion?

    private var scopeUserId: String? { scope == .me ? session.userId : nil }

    var body: some View {
        VStack(spacing: 0) {
            PhaseBanner()
            ScrollView {
                VStack(spacing: 18) {
                    Picker("Classement", selection: $scope) {
                        ForEach(Scope.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    awardsCard

                    criterionChips

                    rankingList
                }
                .padding(16)
            }
        }
        .background(Theme.background.ignoresSafeArea())
    }

    // MARK: - Prix spéciaux

    private var awardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(scope == .group ? "🏆 Les prix du salon" : "🏆 Mes prix")
                .font(.headline)
                .foregroundStyle(Theme.goldLight)
            ForEach(Criterion.allCases) { criterion in
                let best = store.ranking(criterion: criterion, userId: scopeUserId).first
                HStack {
                    Text(criterion.emoji)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(criterion.awardTitle).font(.caption).foregroundStyle(.white.opacity(0.7))
                        Text(best?.candidate.title ?? "—").font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    if let best {
                        Text(best.score.scoreText)
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Theme.goldLight)
                    }
                }
            }
        }
        .card()
    }

    // MARK: - Filtres

    private var criterionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "👑 Général", isOn: criterion == nil) { criterion = nil }
                ForEach(Criterion.allCases) { item in
                    chip(title: "\(item.emoji) \(item.title)", isOn: criterion == item) { criterion = item }
                }
            }
        }
    }

    private func chip(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isOn ? Theme.navy : .white)
                .background(isOn ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.card), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Liste

    @ViewBuilder
    private var rankingList: some View {
        let ranking = store.ranking(criterion: criterion, userId: scopeUserId)
        if ranking.isEmpty {
            VStack(spacing: 8) {
                Text("🗳️").font(.largeTitle)
                Text("Pas encore de notes. Va dans l'onglet Candidates pour noter tes Miss !")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .card()
        } else {
            VStack(spacing: 10) {
                ForEach(Array(ranking.enumerated()), id: \.element.id) { index, item in
                    RankingRow(position: index + 1, item: item, showsVoteCount: scope == .group)
                }
            }
        }
    }
}

private struct RankingRow: View {
    let position: Int
    let item: RankedCandidate
    let showsVoteCount: Bool

    private var medal: String? {
        switch position {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let medal {
                    Text(medal).font(.title2)
                } else {
                    Text("\(position)").font(.headline.monospacedDigit()).foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(item.candidate.title).font(.headline)
                        .strikethrough(item.candidate.eliminated, color: .white.opacity(0.6))
                    if item.candidate.crowned { Text("👑") }
                }
                if let subtitle = item.candidate.subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule().fill(Theme.goldGradient)
                            .frame(width: geo.size.width * item.score / 10)
                    }
                }
                .frame(height: 6)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.score.scoreText)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.goldLight)
                if showsVoteCount {
                    Text("\(item.voteCount) vote\(item.voteCount > 1 ? "s" : "")")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .opacity(item.candidate.eliminated ? 0.6 : 1)
        .padding(12)
        .background(position <= 3 ? Theme.gold.opacity(0.14) : Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}
