import SwiftUI

// Linguagem visual do app: anéis no estilo do app Fitness, páginas no estilo do Notion
enum Estilo {
    // Uma cor por frequência — são os três anéis do Resumo
    static let corHoje = CoresAneis.hoje
    static let corSemana = CoresAneis.semana
    static let corMes = CoresAneis.mes

    static func cor(daFrequencia frequencia: String) -> Color {
        switch frequencia {
        case "Semanal": return corSemana
        case "Mensal": return corMes
        default: return corHoje
        }
    }

    // Cor de destaque de uma rotina: a da categoria, ou a da frequência
    static func cor(categoriaHex: String?, frequencia: String) -> Color {
        categoriaHex.map { Color(hex: $0) } ?? cor(daFrequencia: frequencia)
    }

    // Números grandes arredondados, como no Fitness
    static func numero(_ tamanho: CGFloat) -> Font {
        .system(size: tamanho, weight: .bold, design: .rounded)
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
