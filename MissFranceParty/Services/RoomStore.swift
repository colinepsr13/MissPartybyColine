import Foundation
import FirebaseFirestore

struct RankedCandidate: Identifiable {
    let candidate: Candidate
    let score: Double
    let voteCount: Int
    var id: String { candidate.id ?? candidate.region }
}

/// État temps réel d'un salon : infos, membres, candidates, votes et chat.
/// Les callbacks Firestore arrivent sur le thread principal.
final class RoomStore: ObservableObject {
    let roomId: String

    @Published private(set) var room: Room?
    @Published private(set) var members: [Member] = []
    @Published private(set) var candidates: [Candidate] = []
    @Published private(set) var votes: [Vote] = []
    @Published private(set) var messages: [ChatMessage] = []
    @Published var errorMessage: String?

    private var listeners: [ListenerRegistration] = []
    private var roomRef: DocumentReference { RoomRepository.rooms.document(roomId) }

    init(roomId: String) {
        self.roomId = roomId
    }

    deinit { listeners.forEach { $0.remove() } }

    // MARK: - Écoute temps réel

    func start() {
        guard listeners.isEmpty else { return }

        listeners.append(roomRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error { self.errorMessage = error.localizedDescription; return }
            self.room = try? snapshot?.data(as: Room.self)
        })

        listeners.append(roomRef.collection("members").order(by: "joinedAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot else { return }
                self.members = snapshot.documents.compactMap { try? $0.data(as: Member.self) }
            })

        listeners.append(roomRef.collection("candidates").order(by: "number")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot else { return }
                self.candidates = snapshot.documents.compactMap { try? $0.data(as: Candidate.self) }
            })

        listeners.append(roomRef.collection("votes")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot else { return }
                self.votes = snapshot.documents.compactMap { try? $0.data(as: Vote.self) }
            })

        listeners.append(roomRef.collection("messages").order(by: "createdAt").limit(toLast: 300)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot else { return }
                self.messages = snapshot.documents.compactMap { try? $0.data(as: ChatMessage.self) }
            })
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    // MARK: - Lecture des notes

    func isHost(_ userId: String?) -> Bool {
        guard let userId, let room else { return false }
        return room.hostId == userId
    }

    func vote(userId: String, candidateId: String) -> Vote? {
        votes.first { $0.userId == userId && $0.candidateId == candidateId }
    }

    func myScore(userId: String, candidateId: String, criterion: Criterion) -> Int? {
        vote(userId: userId, candidateId: candidateId)?.score(for: criterion)
    }

    /// Moyenne d'un critère pour une candidate (toutes les copines, ou une seule si `userId` est fourni).
    func average(candidateId: String, criterion: Criterion, userId: String? = nil) -> (value: Double, count: Int)? {
        let values = votes
            .filter { $0.candidateId == candidateId && (userId == nil || $0.userId == userId) }
            .compactMap { $0.score(for: criterion) }
        guard !values.isEmpty else { return nil }
        return (Double(values.reduce(0, +)) / Double(values.count), values.count)
    }

    /// Note générale = moyenne des moyennes de chaque critère noté.
    func overall(candidateId: String, userId: String? = nil) -> (value: Double, count: Int)? {
        let perCriterion = Criterion.allCases.compactMap { average(candidateId: candidateId, criterion: $0, userId: userId) }
        guard !perCriterion.isEmpty else { return nil }
        let value = perCriterion.map(\.value).reduce(0, +) / Double(perCriterion.count)
        let voters = Set(votes.filter { $0.candidateId == candidateId && (userId == nil || $0.userId == userId) && !$0.scores.isEmpty }.map(\.userId))
        return (value, voters.count)
    }

    /// Classement trié du meilleur au moins bon. `criterion == nil` → classement général.
    func ranking(criterion: Criterion?, userId: String? = nil) -> [RankedCandidate] {
        candidates.compactMap { candidate -> RankedCandidate? in
            guard let id = candidate.id else { return nil }
            let result: (value: Double, count: Int)?
            if let criterion {
                result = average(candidateId: id, criterion: criterion, userId: userId)
            } else {
                result = overall(candidateId: id, userId: userId)
            }
            guard let result else { return nil }
            return RankedCandidate(candidate: candidate, score: result.value, voteCount: result.count)
        }
        .sorted { lhs, rhs in
            lhs.score == rhs.score ? lhs.candidate.number < rhs.candidate.number : lhs.score > rhs.score
        }
    }

    /// Nombre de candidates notées (au moins un critère) par une copine.
    func ratedCount(userId: String) -> Int {
        votes.filter { $0.userId == userId && !$0.scores.isEmpty }.count
    }

    // MARK: - Écritures

    func setScore(_ score: Int?, criterion: Criterion, candidateId: String, userId: String) {
        let ref = roomRef.collection("votes").document("\(userId)_\(candidateId)")
        let value: Any = score.map { $0 as Any } ?? FieldValue.delete()
        ref.setData([
            "userId": userId,
            "candidateId": candidateId,
            "scores": [criterion.rawValue: value]
        ], merge: true) { [weak self] error in
            if let error { self?.errorMessage = error.localizedDescription }
        }
    }

    func rename(to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        roomRef.updateData(["name": trimmed], completion: handle)
    }

    func setPhase(_ phase: ShowPhase) {
        roomRef.updateData(["phase": phase.rawValue], completion: handle)
    }

    func setCandidateName(_ name: String, candidateId: String) {
        roomRef.collection("candidates").document(candidateId)
            .updateData(["name": name.trimmingCharacters(in: .whitespacesAndNewlines)], completion: handle)
    }

    func setEliminated(_ eliminated: Bool, candidateId: String) {
        var data: [String: Any] = ["eliminated": eliminated]
        if eliminated { data["crowned"] = false }
        roomRef.collection("candidates").document(candidateId).updateData(data, completion: handle)
    }

    /// Couronne une seule Miss (retire la couronne aux autres).
    func crown(candidateId: String?) {
        let batch = RoomRepository.db.batch()
        for candidate in candidates {
            guard let id = candidate.id else { continue }
            let shouldBeCrowned = id == candidateId
            if candidate.crowned != shouldBeCrowned {
                var data: [String: Any] = ["crowned": shouldBeCrowned]
                if shouldBeCrowned { data["eliminated"] = false }
                batch.updateData(data, forDocument: roomRef.collection("candidates").document(id))
            }
        }
        batch.commit(completion: handle)
    }

    func sendMessage(_ text: String, userId: String, userName: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let message = ChatMessage(userId: userId, userName: userName, text: String(trimmed.prefix(500)), createdAt: Date())
        do {
            _ = try roomRef.collection("messages").addDocument(from: message, completion: handle)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handle(_ error: Error?) {
        if let error { errorMessage = error.localizedDescription }
    }
}
