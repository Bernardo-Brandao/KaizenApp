import SwiftUI

struct DiaAnteriorView: View {
    let rotina: Rotina
    let periodo: String
    var cor: Color = Paleta.destaque
    let aoMudar: () -> Void

    @State private var tarefas: [Tarefa] = []
    @State private var registroAntigo: HistoricoDia?
    @State private var pulado = false
    @State private var tarefaParaAnotar: Tarefa?
    @State private var toques = 0

    private var feitas: Int { tarefas.filter(\.concluidaHoje).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(feitas == tarefas.count && !tarefas.isEmpty ? "Tudo feito" : "\(feitas) de \(tarefas.count) feitas")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(feitas == tarefas.count && !tarefas.isEmpty ? cor : .secondary)
                    BarraProgresso(progresso: tarefas.isEmpty ? 0 : Double(feitas) / Double(tarefas.count), cor: cor, altura: 4)
                }

                if let antigo = registroAntigo {
                    Label("Neste dia o app guardou \(antigo.tarefasConcluidas) de \(antigo.totalTarefas) feitas, mas não quais. Marque as que você fez.",
                          systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(tarefas) { tarefa in
                        LinhaTarefa(tarefa: tarefa, cor: cor) { tocar(tarefa) }
                            .contextMenu {
                                if tarefa.ehValor {
                                    Button { tarefaParaAnotar = tarefa } label: {
                                        Label(tarefa.ehContagem ? "Ajustar contagem" : "Anotar valor", systemImage: "plusminus")
                                    }
                                }
                            }
                    }
                }

                Button {
                    alternarPulo()
                } label: {
                    Label(pulado ? "Desfazer pulo" : textoPular, systemImage: pulado ? "arrow.uturn.backward" : "forward")
                        .font(.subheadline)
                }
                .tint(.secondary)
                .padding(.top, 8)
            }
            .padding(20)
        }
        .navigationTitle(DiasAnterioresView.titulo(periodo, frequencia: rotina.frequencia))
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: toques)
        .sheet(item: $tarefaParaAnotar) { tarefa in
            AnotarValorView(tarefa: tarefa, cor: cor) { valor in
                guard let atual = RotinaDAO().buscar(id: rotina.id ?? 0) else { return }
                ConclusaoTarefa.registrarValor(tarefa, valor: valor, noPeriodo: periodo, rotina: atual)
                depoisDeMudar()
            }
            .presentationDetents([.medium])
        }
        .onAppear(perform: carregar)
    }

    private var textoPular: String {
        switch rotina.frequencia {
        case "Semanal": "Pular esta semana (não conta)"
        case "Mensal": "Pular este mês (não conta)"
        default: "Pular este dia (não conta)"
        }
    }

    private func tocar(_ tarefa: Tarefa) {
        toques += 1
        if tarefa.ehContagem && !tarefa.concluidaHoje {
            ConclusaoTarefa.registrarValor(tarefa, valor: tarefa.valorAtual + 1, noPeriodo: periodo, rotina: rotina)
        } else if tarefa.ehValor {
            tarefaParaAnotar = tarefa
            return
        } else {
            ConclusaoTarefa.alternar(tarefa, noPeriodo: periodo, rotina: rotina)
        }
        depoisDeMudar()
    }

    private func alternarPulo() {
        guard let id = rotina.id else { return }
        if pulado {
            PuloDAO().desfazer(rotinaId: id, periodo: periodo)
        } else {
            PuloDAO().pular(rotinaId: id, periodo: periodo)
        }
        depoisDeMudar()
    }

    private func depoisDeMudar() {
        carregar()
        aoMudar()
        WidgetSync.atualizar()
    }

    private func carregar() {
        guard let id = rotina.id else { return }
        let dao = TarefaDAO()
        var lista = dao.listarNoPeriodo(id, frequencia: rotina.frequencia, periodo: periodo)
        let registro = HistoricoDAO().listarPorRotina(id)
            .first { DataUtil.inicioPeriodo($0.data, frequencia: rotina.frequencia) == periodo }

        if let registro, registro.completoNoDia, lista.contains(where: { !$0.concluidaHoje }) {
            for tarefa in lista where !tarefa.concluidaHoje {
                dao.definirConclusao(tarefaId: tarefa.id ?? -1, periodo: periodo, feita: true)
            }
            lista = dao.listarNoPeriodo(id, frequencia: rotina.frequencia, periodo: periodo)
        }
        tarefas = lista

        let detalhadas = lista.filter(\.concluidaHoje).count
        registroAntigo = registro.flatMap { $0.tarefasConcluidas > detalhadas ? $0 : nil }
        pulado = PuloDAO().periodos(rotinaId: id).contains(periodo)
    }
}
