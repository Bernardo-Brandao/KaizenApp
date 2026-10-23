import SwiftUI

struct EstatisticasView: View {
    let rotina: Rotina
    @StateObject private var viewModel: EstatisticasViewModel

    init(rotina: Rotina) {
        self.rotina = rotina
        _viewModel = StateObject(wrappedValue: EstatisticasViewModel(rotinaId: rotina.id ?? 0, frequencia: rotina.frequencia))
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
                        label: rotuloStreak,
                        icone: "flame.fill"
                    )
                    statCard(
                        valor: "\(Int(viewModel.percentualMedio * 100))%",
                        label: "conclusão média",
                        icone: "chart.bar.fill"
                    )
                }
                .padding(.horizontal)

                // Últimos 7 períodos (dias, semanas ou meses)
                VStack(alignment: .leading, spacing: 10) {
                    Text(tituloGrafico)
                        .font(.headline)
                        .padding(.horizontal)

                    if viewModel.periodosRegistrados == 0 {
                        Text("Ainda não há histórico suficiente.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .padding(.horizontal)
                    } else {
                        // id pela data: dias sem registro não têm id no banco
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(viewModel.ultimos7Periodos, id: \.data) { dia in
                                barraDia(dia)
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 140)
                    }
                }

                // Mapa de calor dos últimos 12 meses
                if viewModel.periodosRegistrados > 0 {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Últimos 12 meses")
                                .font(.headline)
                            Spacer()
                            Text(rotuloCompletosNoAno)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        MapaCalorView(celulas: viewModel.mapaDeCalor, frequencia: rotina.frequencia)
                    }
                    .padding(.horizontal)
                }

                if viewModel.periodosRegistrados == 0 {
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

    private var rotuloStreak: String {
        let um = viewModel.streakAtual == 1
        switch rotina.frequencia {
        case "Semanal": return um ? "semana seguida" : "semanas seguidas"
        case "Mensal": return um ? "mês seguido" : "meses seguidos"
        default: return um ? "dia seguido" : "dias seguidos"
        }
    }

    private var rotuloCompletosNoAno: String {
        let total = viewModel.periodosCompletosNoAno
        switch rotina.frequencia {
        case "Semanal": return total == 1 ? "1 semana completa" : "\(total) semanas completas"
        case "Mensal": return total == 1 ? "1 mês completo" : "\(total) meses completos"
        default: return total == 1 ? "1 dia completo" : "\(total) dias completos"
        }
    }

    private var tituloGrafico: String {
        switch rotina.frequencia {
        case "Semanal": return "Últimas 7 semanas"
        case "Mensal": return "Últimos 7 meses"
        default: return "Últimos 7 dias"
        }
    }

    // `dia.data` é o início do período da barra
    @ViewBuilder
    private func barraDia(_ dia: HistoricoDia) -> some View {
        let ehAtual = dia.data == DataUtil.periodoAtual(frequencia: rotina.frequencia)

        VStack(spacing: 6) {
            Spacer()
            if viewModel.periodosPausados.contains(dia.data) && !dia.completoNoDia {
                // Período pausado: não conta nem quebra o streak
                Image(systemName: "pause.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if dia.id == nil {
                // Dia sem registro: só o contorno, pra mostrar o buraco na sequência
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3]))
                    .frame(height: 8)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(dia.completoNoDia ? AppTheme.primary : AppTheme.primarySoft)
                    .frame(height: max(8, CGFloat(dia.percentual) * 90))
            }
            Text(rotuloBarra(dia.data, atual: ehAtual))
                .font(.caption2.weight(ehAtual ? .semibold : .regular))
                .foregroundColor(ehAtual ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // Diária: dia da semana ("Seg"); Semanal: domingo que abre a semana ("12/10"); Mensal: mês ("Out")
    private func rotuloBarra(_ inicioPeriodo: String, atual: Bool) -> String {
        if atual { return rotina.frequencia == "Diária" ? "Hoje" : "Atual" }
        guard let data = DataUtil.data(de: inicioPeriodo) else { return "" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        switch rotina.frequencia {
        case "Semanal": formatter.dateFormat = "dd/MM"
        case "Mensal": formatter.dateFormat = "MMM"
        default: formatter.dateFormat = "EEE"
        }
        return formatter.string(from: data).replacingOccurrences(of: ".", with: "").capitalized
    }
}
