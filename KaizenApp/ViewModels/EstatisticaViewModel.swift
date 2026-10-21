import Foundation
import Combine

class EstatisticasViewModel: ObservableObject {
    @Published var historico: [HistoricoDia] = []
    private let dao = HistoricoDAO()
    private let rotinaId: Int64

    init(rotinaId: Int64) {
        self.rotinaId = rotinaId
    }

    func carregar() {
        historico = dao.listarPorRotina(rotinaId)
    }

    // Sequência atual de dias de calendário seguidos com 100% das tarefas concluídas.
    // Hoje só entra se já estiver completo — enquanto o dia está em andamento, conta a partir de ontem.
    // Um dia sem registro (app não aberto) quebra a sequência.
    var streakAtual: Int {
        let completos = Set(historico.filter { $0.completoNoDia }.map { $0.data })
        let hoje = DataUtil.hoje()

        var dia: String? = completos.contains(hoje) ? hoje : DataUtil.diaAnterior(a: hoje)
        var streak = 0
        while let atual = dia, completos.contains(atual) {
            streak += 1
            dia = DataUtil.diaAnterior(a: atual)
        }
        return streak
    }

    // Percentual médio de conclusão entre todos os dias registrados
    var percentualMedio: Double {
        guard !historico.isEmpty else { return 0 }
        let soma = historico.reduce(0.0) { $0 + $1.percentual }
        return soma / Double(historico.count)
    }

    var diasRegistrados: Int {
        historico.count
    }

    // Os 7 dias do calendário até hoje, do mais antigo pro mais recente (pra desenhar da esquerda pra direita).
    // Dias sem registro entram com id nil e 0 tarefas, pra aparecerem como barra vazia.
    var ultimos7Dias: [HistoricoDia] {
        let porData = Dictionary(historico.map { ($0.data, $0) }, uniquingKeysWith: { primeiro, _ in primeiro })

        var dias: [String] = [DataUtil.hoje()]
        while dias.count < 7, let anterior = DataUtil.diaAnterior(a: dias[dias.count - 1]) {
            dias.append(anterior)
        }

        return dias.reversed().map { data in
            porData[data] ?? HistoricoDia(id: nil, rotinaId: rotinaId, data: data, totalTarefas: 0, tarefasConcluidas: 0)
        }
    }
}
