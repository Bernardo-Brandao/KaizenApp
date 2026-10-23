import SwiftUI

// Mapa de calor dos últimos 12 meses (estilo GitHub).
// Diária: uma coluna por semana (domingo em cima), rolando na horizontal.
// Semanal: uma célula por semana. Mensal: uma célula por mês.
struct MapaCalorView: View {
    let celulas: [CelulaMapa]
    let frequencia: String

    private let tamanho: CGFloat = 12
    private let espaco: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch frequencia {
            case "Semanal": gradeSemanal
            case "Mensal": linhaMensal
            default: gradeDiaria
            }
            legenda
        }
    }

    // MARK: - Layouts

    private var gradeDiaria: some View {
        // As células já começam num domingo, então cada bloco de 7 é uma semana
        let semanas = stride(from: 0, to: celulas.count, by: 7).map {
            Array(celulas[$0..<min($0 + 7, celulas.count)])
        }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: espaco) {
                ForEach(semanas.indices, id: \.self) { indice in
                    VStack(alignment: .leading, spacing: espaco) {
                        Text(rotuloMes(semana: semanas[indice], primeira: indice == 0))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .fixedSize()
                            .frame(width: tamanho, height: 11, alignment: .leading)
                        ForEach(semanas[indice]) { celula in
                            quadrado(celula)
                                .frame(width: tamanho, height: tamanho)
                        }
                    }
                }
            }
        }
        .defaultScrollAnchor(.trailing)   // abre mostrando os dias mais recentes
    }

    private var gradeSemanal: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: espaco), count: 13), spacing: espaco) {
            ForEach(celulas) { celula in
                quadrado(celula)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    private var linhaMensal: some View {
        HStack(spacing: 6) {
            ForEach(celulas) { celula in
                VStack(spacing: 4) {
                    quadrado(celula)
                        .aspectRatio(1, contentMode: .fit)
                    Text(inicialDoMes(celula.periodo))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Célula e legenda

    private func quadrado(_ celula: CelulaMapa) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(cor(celula))
            .accessibilityLabel(descricao(celula))
    }

    private var legenda: some View {
        HStack(spacing: 4) {
            Text("Menos").font(.caption2).foregroundColor(.secondary)
            ForEach([0.0, 0.3, 0.7, 1.0], id: \.self) { nivel in
                RoundedRectangle(cornerRadius: 3)
                    .fill(corPorNivel(nivel))
                    .frame(width: 10, height: 10)
            }
            Text("Mais").font(.caption2).foregroundColor(.secondary)
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 10, height: 10)
            Text("Pausado").font(.caption2).foregroundColor(.secondary)
        }
        .accessibilityHidden(true)
    }

    // Sem registro → vazio; pausado e não completo → cinza; senão, intensidade pelo percentual
    private func cor(_ celula: CelulaMapa) -> Color {
        if celula.pausado && !celula.completo { return Color.secondary.opacity(0.3) }
        guard let percentual = celula.percentual else { return AppTheme.cardBackground }
        return corPorNivel(celula.completo ? 1 : percentual)
    }

    private func corPorNivel(_ nivel: Double) -> Color {
        switch nivel {
        case 1...: return AppTheme.primary
        case 0.5..<1: return AppTheme.primary.opacity(0.6)
        case 0.0001..<0.5: return AppTheme.primary.opacity(0.3)
        default: return AppTheme.primarySoft.opacity(0.5)
        }
    }

    // MARK: - Rótulos

    // Mostra o mês na coluna onde ele começa (e na primeira coluna)
    private func rotuloMes(semana: [CelulaMapa], primeira: Bool) -> String {
        let inicioDeMes = semana.first { $0.periodo.hasSuffix("-01") }
        guard let referencia = inicioDeMes ?? (primeira ? semana.first : nil),
              let data = DataUtil.data(de: referencia.periodo)
        else { return "" }
        return Self.formatador("MMM").string(from: data).replacingOccurrences(of: ".", with: "").capitalized
    }

    private func inicialDoMes(_ periodo: String) -> String {
        guard let data = DataUtil.data(de: periodo) else { return "" }
        return String(Self.formatador("MMM").string(from: data).prefix(1)).uppercased()
    }

    private func descricao(_ celula: CelulaMapa) -> String {
        let data = DataUtil.data(de: celula.periodo).map { Self.formatador("d 'de' MMMM").string(from: $0) } ?? celula.periodo
        if celula.pausado && !celula.completo { return "\(data): pausado" }
        guard let percentual = celula.percentual else { return "\(data): sem registro" }
        return "\(data): \(Int(percentual * 100))%"
    }

    private static func formatador(_ formato: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = formato
        return formatter
    }
}
