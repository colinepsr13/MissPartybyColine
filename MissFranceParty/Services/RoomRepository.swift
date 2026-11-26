import Foundation
import FirebaseFirestore

enum RoomError: LocalizedError {
    case notFound
    case invalidCode

    var errorDescription: String? {
        switch self {
        case .notFound: return "Aucun salon ne correspond à ce code. Vérifie avec ta copine !"
        case .invalidCode: return "Le code doit contenir 6 caractères."
        }
    }
}

/// Opérations ponctuelles : créer / rejoindre / quitter un salon.
enum RoomRepository {
    static var db: Firestore { Firestore.firestore() }
    static var rooms: CollectionReference { db.collection("rooms") }

    static let codeLength = 6
    // Pas de 0/O ni 1/I pour éviter les confusions quand on dicte le code.
    private static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func normalize(code: String) -> String {
        code.uppercased().filter { !$0.isWhitespace }
    }

    private static func randomCode() -> String {
        String((0..<codeLength).map { _ in alphabet.randomElement()! })
    }

    private static func uniqueCode() async throws -> String {
        for _ in 0..<10 {
            let code = randomCode()
            let existing = try await rooms.whereField("code", isEqualTo: code).limit(to: 1).getDocuments()
            if existing.documents.isEmpty { return code }
        }
        return randomCode()
    }

    /// Crée un salon avec les 30 candidates et renvoie son identifiant.
    static func createRoom(name: String, userId: String, userName: String) async throws -> String {
        let code = try await uniqueCode()
        let roomRef = rooms.document()
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let room = Room(
            name: trimmed.isEmpty ? "Soirée Miss France 2027" : trimmed,
            code: code,
            hostId: userId,
            createdAt: Date(),
            memberIds: [userId],
            phase: ShowPhase.avant.rawValue
        )

        let batch = db.batch()
        try batch.setData(from: room, forDocument: roomRef)
        try batch.setData(from: Member(name: userName, joinedAt: Date()),
                          forDocument: roomRef.collection("members").document(userId))
        for item in CandidateCatalog.defaults {
            try batch.setData(from: item.candidate,
                              forDocument: roomRef.collection("candidates").document(item.docId))
        }
        try await batch.commit()
        return roomRef.documentID
    }

    /// Rejoint un salon grâce à son code et renvoie son identifiant.
    static func joinRoom(code rawCode: String, userId: String, userName: String) async throws -> String {
        let code = normalize(code: rawCode)
        guard code.count == codeLength else { throw RoomError.invalidCode }

        let snapshot = try await rooms.whereField("code", isEqualTo: code).limit(to: 1).getDocuments()
        guard let doc = snapshot.documents.first else { throw RoomError.notFound }

        let batch = db.batch()
        batch.updateData(["memberIds": FieldValue.arrayUnion([userId])], forDocument: doc.reference)
        try batch.setData(from: Member(name: userName, joinedAt: Date()),
                          forDocument: doc.reference.collection("members").document(userId))
        try await batch.commit()
        return doc.documentID
    }

    static func leaveRoom(roomId: String, userId: String) async throws {
        let roomRef = rooms.document(roomId)
        let batch = db.batch()
        batch.updateData(["memberIds": FieldValue.arrayRemove([userId])], forDocument: roomRef)
        batch.deleteDocument(roomRef.collection("members").document(userId))
        try await batch.commit()
    }
}
