import SwiftUI

enum AppTheme {
    // Azul moderno e claro — cor principal do app
    static let primary = Color(hex: "3DA9FC")

    // Tom mais escuro do mesmo azul, para textos/ícones que precisam de mais contraste
    static let primaryDark = Color(hex: "1B6FA8")

    // Versão suave (com transparência) para fundos de cards e destaques discretos
    static let primarySoft = primary.opacity(0.15)

    // Fundo padrão de cards, adaptado automaticamente a modo claro/escuro
    static let cardBackground = Color(.secondarySystemBackground)
}

// Helper pra converter cores em hex (ex: "3DA9FC") em Color do SwiftUI
extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
