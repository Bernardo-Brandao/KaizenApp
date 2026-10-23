import SwiftUI

struct EstatisticasView: View {
    let rotina: Rotina
    @StateObject private var viewModel: EstatisticasViewModel

    init(rotina: Rotina) {
        self.rotina = rotina
        _viewModel = StateObject(wrappedValue: EstatisticasViewModel(rotinaId: rotina.id ?? 0, frequencia: rotina.frequencia, diasSemana: rotina.diasSemana))
    }

    @State private var cor: Color = AppTheme.primary
    private let colunas = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cabeçalho: emoji e nome, como a página da rotina
                HStack(spacing: 12) {
                    Text(rotina.iconeExibido).font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rotina.nome).font(.title2.bold())
                        Text(rotina.frequenciaDescrita).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                // Cartões de destaque, estilo "Tendências" do Fitness
                LazyVGrid(columns: colunas, spacing: 12) {
                    cartao("Sequência", icone: "flame.fill", corIcone: .orange,
                           valor: "\(viewModel.streakAtual)", unidade: rotuloUnidade(viewModel.streakAtual))
                    cartao("Recorde", icone: "trophy.fill", corIcone: .yellow,
                           valor: "\(viewModel.recorde)", unidade: rotuloUnidade(viewModel.recorde))
                    cartao("Conclusão média", icone: "percent", corIcone: cor,
                           valor: "\(Int(viewModel.percentualMedio * 100))", unidade: "%")
                    cartao("Completos", icone: "checkmark.seal.fill", corIcone: Estilo.corSemana,
                           valor: "\(viewModel.periodosCompletos)", unidade: rotuloUnidade(viewModel.periodosCompletos))
                }

                // Últimos 7 períodos (dias, semanas ou meses)
                secao(tituloGrafico) {
                    if viewModel.periodosRegistrados == 0 {
                        Text("Complete tarefas por alguns dias para começar a ver suas estatísticas aqui.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        // id pela data: dias sem registro não têm id no banco
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(viewModel.ultimos7Periodos, id: \.data) { dia in
                                barraDia(dia)
                            }
                        }
                        .frame(height: 140)
                    }
                }

                // Mapa de calor dos últimos 12 meses
                if viewModel.periodosRegistrados > 0 {
                    secao("Últimos 12 meses", detalhe: rotuloCompletosNoAno) {
                        MapaCalorView(celulas: viewModel.mapaDeCalor, frequencia: rotina.frequencia, cor: cor)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Estatísticas")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.carregar()
            let categoria = CategoriaDAO().listarTodas().first { $0.id == rotina.categoriaId }
            cor = Estilo.cor(categoriaHex: categoria?.corHex, frequencia: rotina.frequencia)
        }
    }

    private func cartao(_ titulo: String, icone: String, corIcone: Color, valor: String, unidade: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(titulo, systemImage: icone)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(corIcone)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(valor).font(Estilo.numero(30))
                Text(unidade).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
    }

    private func secao<Conteudo: View>(_ titulo: String, detalhe: String? = nil,
                                       @ViewBuilder conteudo: () -> Conteudo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(titulo).font(.headline)
                Spacer()
                if let detalhe {
                    Text(detalhe).font(.caption).foregroundStyle(.secondary)
                }
            }
            conteudo()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
    }

    // "dias", "semanas" ou "meses" (singular quando é 1)
    private func rotuloUnidade(_ valor: Int) -> String {
        let um = valor == 1
        switch rotina.frequencia {
        case "Semanal": return um ? "semana" : "semanas"
        case "Mensal": return um ? "mês" : "meses"
        default: return um ? "dia" : "dias"
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
                    .fill(dia.completoNoDia ? cor : cor.opacity(0.3))
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
