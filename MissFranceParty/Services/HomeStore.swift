import Foundation
import FirebaseFirestore

/// Liste en temps réel des salons dont l'utilisatrice fait partie.
final class HomeStore: ObservableObject {
    @Published private(set) var rooms: [Room] = []
    @Published private(set) var isLoading = true

    private var listener: ListenerRegistration?
    private var currentUserId: String?

    func start(userId: String) {
        guard currentUserId != userId else { return }
        stop()
        currentUserId = userId
        listener = RoomRepository.rooms
            .whereField("memberIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                self.isLoading = false
                guard let snapshot else { return }
                self.rooms = snapshot.documents
                    .compactMap { try? $0.data(as: Room.self) }
                    .sorted { $0.createdAt > $1.createdAt }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
        currentUserId = nil
    }

    deinit { listener?.remove() }
}
