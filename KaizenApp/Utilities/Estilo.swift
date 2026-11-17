import SwiftUI

enum Estilo {
    static func cor(categoriaHex: String?, frequencia: String) -> Color {
        categoriaHex.map { Color(hex: $0) } ?? Paleta.destaque
    }

    static func numero(_ tamanho: CGFloat) -> Font {
        .system(size: tamanho, weight: .semibold)
    }

    static let cantoCartao: CGFloat = 16
}

struct IconeRotina: View {
    let icone: String
    var tamanho: CGFloat = 36

    var body: some View {
        Text(icone)
            .font(.system(size: tamanho * 0.6))
            .frame(width: tamanho, height: tamanho)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: tamanho * 0.25))
    }
}
