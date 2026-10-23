import SwiftUI

// Aba Prêmios, no estilo dos prêmios do app Fitness: medalhas coloridas quando conquistadas,
// cinza enquanto ainda não
struct PremiosView: View {
    @StateObject private var viewModel = ResumoViewModel()

    private let colunas = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    resumo
                    ForEach(Premio.Grupo.allCases, id: \.self) { grupo in
                        VStack(alignment: .leading, spacing: 14) {
                            Text(grupo.rawValue).font(.title3.bold())
                            LazyVGrid(columns: colunas, spacing: 20) {
                                ForEach(viewModel.premios.filter { $0.grupo == grupo }) { premio in
                                    MedalhaView(premio: premio)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Prêmios")
            .onAppear { viewModel.carregar() }
        }
    }

    private var resumo: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(viewModel.premiosConquistados)").font(Estilo.numero(40))
            Text("de \(viewModel.premios.count) conquistados")
                .foregroundStyle(.secondary)
        }
    }
}

struct MedalhaView: View {
    let premio: Premio

    private var cor: Color { premio.grupo == .sequencia ? .orange : Estilo.corSemana }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(premio.conquistado ? cor.opacity(0.18) : Color(.tertiarySystemFill))
                Circle()
                    .strokeBorder(premio.conquistado ? cor : Color(.quaternaryLabel), lineWidth: 3)
                Image(systemName: premio.simbolo)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(premio.conquistado ? cor : Color(.tertiaryLabel))
            }
            .frame(width: 80, height: 80)
            Text(premio.titulo)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(premio.conquistado ? .primary : .secondary)
                .multilineTextAlignment(.center)
            Text(premio.descricao)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(premio.conquistado ? "Conquistado" : "Ainda não conquistado")
    }
}
