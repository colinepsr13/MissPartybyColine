import SwiftUI

/// Chat du salon pour commenter l'émission en direct, même à distance.
struct ChatView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var store: RoomStore
    @State private var draft = ""
    @FocusState private var focused: Bool

    private let reactions = ["😍", "👑", "🔥", "😱", "👏", "😂", "💅", "😭"]

    var body: some View {
        VStack(spacing: 0) {
            PhaseBanner()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if store.messages.isEmpty {
                            Text("Lance la conversation ! 🍿")
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.top, 40)
                        }
                        ForEach(store.messages) { message in
                            MessageBubble(message: message, isMine: message.userId == session.userId)
                                .id(message.id ?? "")
                        }
                    }
                    .padding(12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: store.messages.count) { _, _ in
                    if let last = store.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
                .onAppear {
                    if let last = store.messages.last?.id { proxy.scrollTo(last, anchor: .bottom) }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(reactions, id: \.self) { emoji in
                        Button(emoji) { send(emoji) }
                            .font(.title2)
                            .padding(6)
                            .background(Theme.card, in: Circle())
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 6)

            HStack(spacing: 10) {
                TextField("Ton commentaire…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($focused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
                Button {
                    send(draft)
                    draft = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(Theme.navy)
                        .padding(12)
                        .background(Theme.goldGradient, in: Circle())
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func send(_ text: String) {
        guard let userId = session.userId else { return }
        store.sendMessage(text, userId: userId, userName: session.displayName)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 50) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 3) {
                if !isMine {
                    Text(message.userName).font(.caption2.weight(.bold)).foregroundStyle(Theme.rose)
                }
                Text(message.text)
                    .font(isOnlyEmoji ? .largeTitle : .body)
                    .foregroundStyle(isMine ? Theme.navy : .white)
                    .padding(.horizontal, isOnlyEmoji ? 4 : 12)
                    .padding(.vertical, isOnlyEmoji ? 0 : 8)
                    .background {
                        if !isOnlyEmoji {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isMine ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.card))
                        }
                    }
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            if !isMine { Spacer(minLength: 50) }
        }
    }

    private var isOnlyEmoji: Bool {
        message.text.count <= 3 && message.text.unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmojiPresentation
                || scalar.value == 0xFE0F || scalar.value == 0x200D
                || (scalar.properties.isEmoji && scalar.value > 0x238C)
        }
    }
}
