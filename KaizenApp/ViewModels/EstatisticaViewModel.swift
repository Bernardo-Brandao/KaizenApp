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

    // Sequência atual de dias consecutivos com 100% das tarefas concluídas,
    // contando a partir do dia mais recente registrado
    var streakAtual: Int {
        var streak = 0
        for dia in historico {
            if dia.completoNoDia {
                streak += 1
            } else {
                break
            }
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
