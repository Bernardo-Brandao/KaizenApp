import SwiftUI

// Selo "Rotina completa!" com confetes, mostrado por cima da tela da rotina.
// Quem mostra é responsável por esconder (DetalheRotinaView some com ela depois de ~2s).
struct ComemoracaoView: View {
    let frequencia: String

    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento
    @State private var apareceu = false

    private var subtitulo: String {
        switch frequencia {
        case "Semanal": return "Semana concluída"
        case "Mensal": return "Mês concluído"
        default: return "Dia concluído"
        }
    }

    // Confetes: posição final, cor e tamanho sorteados uma vez
    private let confetes: [Confete] = (0..<28).map { _ in Confete() }

    var body: some View {
        ZStack {
            if !reduzirMovimento {
                ForEach(confetes) { confete in
                    Circle()
                        .fill(confete.cor)
                        .frame(width: confete.tamanho, height: confete.tamanho)
                        .offset(apareceu ? confete.destino : .zero)
                        .opacity(apareceu ? 0 : 1)
                }
            }

            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundColor(AppTheme.primary)
                Text("Rotina completa!")
                    .font(.title3.bold())
                Text(subtitulo)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .scaleEffect(apareceu || reduzirMovimento ? 1 : 0.6)
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                apareceu = true
            }
        }
        .allowsHitTesting(false)
    }
}

private struct Confete: Identifiable {
    let id = UUID()
    let cor: Color = [AppTheme.primary, .orange, .pink, .green, .yellow, .purple].randomElement()!
    let tamanho = CGFloat.random(in: 6...11)
    let destino: CGSize = {
        let angulo = Double.random(in: 0..<(2 * .pi))
        let distancia = Double.random(in: 110...190)
        return CGSize(width: cos(angulo) * distancia, height: sin(angulo) * distancia)
    }()
}
