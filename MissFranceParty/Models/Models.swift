import Foundation
import FirebaseFirestore

// MARK: - Critères de notation

enum Criterion: String, CaseIterable, Identifiable, Codable {
    case tenue
    case maquillage
    case danse
    case discours

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tenue: return "Tenue"
        case .maquillage: return "Maquillage"
        case .danse: return "Danse"
        case .discours: return "Discours"
        }
    }

    var emoji: String {
        switch self {
        case .tenue: return "👗"
        case .maquillage: return "💄"
        case .danse: return "💃"
        case .discours: return "🎤"
        }
    }

    /// Libellé du "prix spécial" décerné par le salon.
    var awardTitle: String {
        switch self {
        case .tenue: return "Meilleure tenue"
        case .maquillage: return "Meilleur maquillage"
        case .danse: return "Meilleure danse"
        case .discours: return "Meilleur discours"
        }
    }
}

// MARK: - Étapes de l'émission

enum ShowPhase: String, CaseIterable, Identifiable, Codable {
    case avant
    case defileRegional
    case top15
    case top5
    case couronnement
    case termine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .avant: return "Avant le show"
        case .defileRegional: return "Défilés des 31 Miss"
        case .top15: return "Top 15"
        case .top5: return "Top 5"
        case .couronnement: return "Couronnement"
        case .termine: return "C'est fini !"
        }
    }

    var emoji: String {
        switch self {
        case .avant: return "🍿"
        case .defileRegional: return "✨"
        case .top15: return "🔥"
        case .top5: return "😱"
        case .couronnement: return "👑"
        case .termine: return "🎉"
        }
    }
}

// MARK: - Documents Firestore

struct Room: Identifiable, Codable {
    @DocumentID var id: String? = nil
    var name: String
    var code: String
    var hostId: String
    var createdAt: Date
    var memberIds: [String]
    var phase: String

    var showPhase: ShowPhase { ShowPhase(rawValue: phase) ?? .avant }
}

struct Member: Identifiable, Codable {
    @DocumentID var id: String? = nil
    var name: String
    var joinedAt: Date
}

struct Candidate: Identifiable, Codable {
    @DocumentID var id: String? = nil
    var number: Int
    var region: String
    /// Prénom + nom de la candidate (modifiable par l'organisatrice du salon).
    var name: String
    var eliminated: Bool
    var crowned: Bool

    var title: String { "Miss \(region)" }
    var subtitle: String? { name.trimmingCharacters(in: .whitespaces).isEmpty ? nil : name }
}

struct Vote: Identifiable, Codable {
    @DocumentID var id: String? = nil
    var userId: String
    var candidateId: String
    var scores: [String: Int]

    func score(for criterion: Criterion) -> Int? { scores[criterion.rawValue] }
}

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String? = nil
    var userId: String
    var userName: String
    var text: String
    var createdAt: Date
}

// MARK: - Liste des 31 régions

enum CandidateCatalog {
    /// Les 31 régions représentées à l'élection de Miss France.
    /// Les noms des candidates peuvent être ajoutés dans l'app par l'organisatrice du salon
    /// dès qu'ils sont connus.
    static let regions: [String] = [
        "Alsace", "Aquitaine", "Auvergne", "Bourgogne", "Bretagne",
        "Centre-Val de Loire", "Champagne-Ardenne", "Corse", "Côte d'Azur", "Franche-Comté",
        "Guadeloupe", "Guyane", "Île-de-France", "Languedoc", "Limousin",
        "Lorraine", "Martinique", "Mayotte", "Midi-Pyrénées", "Nord-Pas-de-Calais", "Normandie",
        "Nouvelle-Calédonie", "Pays de la Loire", "Picardie", "Poitou-Charentes", "Provence",
        "Réunion", "Rhône-Alpes", "Roussillon", "Saint-Martin & Saint-Barthélemy", "Tahiti"
    ]

    static var defaults: [(docId: String, candidate: Candidate)] {
        regions.enumerated().map { index, region in
            let number = index + 1
            return (
                String(format: "c%02d", number),
                Candidate(number: number, region: region, name: "", eliminated: false, crowned: false)
            )
        }
    }
}
