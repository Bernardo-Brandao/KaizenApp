import SwiftUI

// Linguagem visual do app: páginas no estilo do Notion, tons neutros e um único destaque (Paleta)
enum Estilo {
    // Cor de destaque de uma rotina: a da categoria, ou o destaque do app
    static func cor(categoriaHex: String?, frequencia: String) -> Color {
        categoriaHex.map { Color(hex: $0) } ?? Paleta.destaque
    }

    // Números grandes, sem enfeite
    static func numero(_ tamanho: CGFloat) -> Font {
        .system(size: tamanho, weight: .semibold)
    }

    static let cantoCartao: CGFloat = 16
}

// Ícone (emoji) da rotina num quadradinho, como o ícone de página do Notion
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
