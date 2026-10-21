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

    // Os últimos 7 dias, do mais antigo pro mais recente (pra desenhar da esquerda pra direita)
    var ultimos7Dias: [HistoricoDia] {
        Array(historico.prefix(7)).reversed()
    }
}
