import SwiftUI

struct DiasAnterioresView: View {
    let rotina: Rotina
    var cor: Color = Paleta.destaque
    let aoMudar: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var linhas: [LinhaPeriodo] = []

    struct LinhaPeriodo: Identifiable {
        let periodo: String
        let registro: HistoricoDia?
        let folga: Bool
        let pausado: Bool
        let pulado: Bool
        let tarefasDoPeriodo: Int
        var id: String { periodo }

        var feito: Bool { registro?.completoNoDia ?? false }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(linhas) { linha in
                        if linha.folga || linha.tarefasDoPeriodo == 0 {
                            rotulo(linha)
                        } else {
                            NavigationLink {
                                DiaAnteriorView(rotina: rotina, periodo: linha.periodo, cor: cor) {
                                    carregar()
                                    aoMudar()
                                }
                            } label: {
                                rotulo(linha)
                            }
                        }
                    }
                } footer: {
                    Text("Esqueceu de marcar? Toque no dia e marque as tarefas que fez.")
                }
            }
            .navigationTitle("Dias anteriores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .onAppear(perform: carregar)
        }
    }

    private func rotulo(_ linha: LinhaPeriodo) -> some View {
        HStack {
            Text(Self.titulo(linha.periodo, frequencia: rotina.frequencia))
                .foregroundStyle(.primary)
            Spacer()
            estado(linha)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private func estado(_ linha: LinhaPeriodo) -> some View {
        if linha.feito {
            Label("Feito", systemImage: "checkmark.circle.fill").foregroundStyle(cor)
        } else if linha.folga {
            Label("Folga", systemImage: "moon.zzz").foregroundStyle(.secondary)
        } else if linha.pulado {
            Label("Pulado", systemImage: "forward").foregroundStyle(.secondary)
        } else if linha.pausado {
            Label("Pausada", systemImage: "pause.circle").foregroundStyle(.secondary)
        } else if let registro = linha.registro, registro.totalTarefas > 0 {
            Text("\(registro.tarefasConcluidas) de \(registro.totalTarefas)").foregroundStyle(.secondary)
        } else {
            Text("Sem registro").foregroundStyle(.tertiary)
        }
    }

    private func carregar() {
        guard let id = rotina.id else { return }
        let estatisticas = EstatisticasViewModel(rotinaId: id, frequencia: rotina.frequencia, diasSemana: rotina.diasSemana)
        estatisticas.carregar()
        let pulados = PuloDAO().periodos(rotinaId: id)
        let pausas = EstatisticasViewModel.periodosPausados(PausaDAO().listar(rotinaId: id), frequencia: rotina.frequencia)
        let registros = Dictionary(estatisticas.historico.map { (DataUtil.inicioPeriodo($0.data, frequencia: rotina.frequencia), $0) },
                                   uniquingKeysWith: { primeiro, _ in primeiro })
        let tarefaDao = TarefaDAO()

        linhas = Self.periodosAnteriores(frequencia: rotina.frequencia).map { periodo in
            LinhaPeriodo(
                periodo: periodo,
                registro: registros[periodo],
                folga: EstatisticasViewModel.ehFolga(periodo, frequencia: rotina.frequencia, diasSemana: rotina.diasSemana),
                pausado: pausas.contains(periodo),
                pulado: pulados.contains(periodo),
                tarefasDoPeriodo: tarefaDao.listarPorRotina(id, frequencia: rotina.frequencia, dia: periodo).count
            )
        }
    }

    static func periodosAnteriores(frequencia: String, hoje: String = DataUtil.hoje()) -> [String] {
        let quantidade = frequencia == "Semanal" ? 8 : frequencia == "Mensal" ? 6 : 14
        var periodos: [String] = []
        var periodo = DataUtil.periodoAnterior(a: DataUtil.periodoAtual(frequencia: frequencia, hoje: hoje), frequencia: frequencia)
        while let p = periodo, periodos.count < quantidade {
            periodos.append(p)
            periodo = DataUtil.periodoAnterior(a: p, frequencia: frequencia)
        }
        return periodos
    }

    static func titulo(_ periodo: String, frequencia: String, hoje: String = DataUtil.hoje()) -> String {
        guard let data = DataUtil.data(de: periodo) else { return periodo }
        let ptBR = Locale(identifier: "pt_BR")
        switch frequencia {
        case "Semanal":
            return "Semana de " + data.formatted(.dateTime.day().month(.abbreviated).locale(ptBR))
        case "Mensal":
            let texto = data.formatted(.dateTime.month(.wide).year().locale(ptBR))
            return texto.prefix(1).uppercased() + texto.dropFirst()
        default:
            if periodo == DataUtil.diaAnterior(a: hoje) { return "Ontem" }
            let texto = data.formatted(.dateTime.weekday(.wide).day().month(.abbreviated).locale(ptBR))
            return texto.prefix(1).uppercased() + texto.dropFirst()
        }
    }
}
