import SwiftUI

struct EstatisticasView: View {
    let rotina: Rotina
    @StateObject private var viewModel: EstatisticasViewModel

    init(rotina: Rotina) {
        self.rotina = rotina
        _viewModel = StateObject(wrappedValue: EstatisticasViewModel(rotinaId: rotina.id ?? 0))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text(rotina.nome)
                    .font(.title2.bold())
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Cards de destaque: streak e percentual médio
                HStack(spacing: 14) {
                    statCard(
                        valor: "\(viewModel.streakAtual)",
                        label: viewModel.streakAtual == 1 ? "dia seguido" : "dias seguidos",
                        icone: "flame.fill"
                    )
                    statCard(
                        valor: "\(Int(viewModel.percentualMedio * 100))%",
                        label: "conclusão média",
                        icone: "chart.bar.fill"
                    )
                }
                .padding(.horizontal)

                // Últimos 7 dias
                VStack(alignment: .leading, spacing: 10) {
                    Text("Últimos 7 dias")
                        .font(.headline)
                        .padding(.horizontal)

                    if viewModel.ultimos7Dias.isEmpty {
                        Text("Ainda não há histórico suficiente.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .padding(.horizontal)
                    } else {
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(viewModel.ultimos7Dias) { dia in
                                barraDia(dia)
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 140)
                    }
                }

                if viewModel.diasRegistrados == 0 {
                    Text("Complete tarefas por alguns dias para começar a ver suas estatísticas aqui.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Estatísticas")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.carregar() }
    }

    @ViewBuilder
    private func statCard(valor: String, label: String, icone: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icone)
                .font(.title3)
                .foregroundColor(AppTheme.primary)
            Text(valor)
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
        )
    }

    @ViewBuilder
    private func barraDia(_ dia: HistoricoDia) -> some View {
        VStack(spacing: 6) {
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(dia.completoNoDia ? AppTheme.primary : AppTheme.primarySoft)
                .frame(height: max(8, CGFloat(dia.percentual) * 90))
            Text(diaAbreviado(dia.data))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func diaAbreviado(_ dataString: String) -> String {
        let formatterEntrada = DateFormatter()
        formatterEntrada.dateFormat = "yyyy-MM-dd"
        guard let data = formatterEntrada.date(from: dataString) else { return "" }

        let formatterSaida = DateFormatter()
        formatterSaida.dateFormat = "EEE"
        formatterSaida.locale = Locale(identifier: "pt_BR")
        return formatterSaida.string(from: data).capitalized
    }
}
