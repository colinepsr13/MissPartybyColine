import SwiftUI

enum Theme {
    static let gold = Color(red: 0.86, green: 0.69, blue: 0.33)
    static let goldLight = Color(red: 0.98, green: 0.88, blue: 0.62)
    static let rose = Color(red: 0.93, green: 0.37, blue: 0.57)
    static let navy = Color(red: 0.06, green: 0.07, blue: 0.20)
    static let night = Color(red: 0.13, green: 0.08, blue: 0.27)
    static let card = Color.white.opacity(0.08)

    static let background = LinearGradient(
        colors: [navy, night, Color(red: 0.25, green: 0.08, blue: 0.25)],
        startPoint: .top, endPoint: .bottom
    )

    static let goldGradient = LinearGradient(
        colors: [goldLight, gold], startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.navy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.goldGradient, in: RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.goldLight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 16).stroke(Theme.gold, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }

    /// Fond dégradé de l'app, sans le fond gris par défaut des listes.
    func themedBackground() -> some View {
        self.scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
    }
}

struct CrownTitle: View {
    var text: String
    var body: some View {
        VStack(spacing: 6) {
            Text("👑").font(.system(size: 56))
            Text(text)
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(Theme.goldGradient)
                .multilineTextAlignment(.center)
        }
    }
}

extension Double {
    var scoreText: String { String(format: "%.1f", self) }
}
