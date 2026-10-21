import Foundation
import Combine

class EstatisticasViewModel: ObservableObject {
    @Published var historico: [HistoricoDia] = []
    @Published var periodosPausados: Set<String> = []   // inícios de período em que a rotina esteve pausada
    private let dao = HistoricoDAO()
    private let rotinaId: Int64
    let frequencia: String

    init(rotinaId: Int64, frequencia: String) {
        self.rotinaId = rotinaId
        self.frequencia = frequencia
    }

    func carregar() {
        historico = dao.listarPorRotina(rotinaId)

        periodosPausados = Self.periodosPausados(PausaDAO().listar(rotinaId: rotinaId), frequencia: frequencia)
    }

    // Todo período que teve pelo menos um dia de pausa fica "neutro"
    static func periodosPausados(_ pausas: [(inicio: String, fim: String)], frequencia: String) -> Set<String> {
        var pausados: Set<String> = []
        for pausa in pausas {
            let primeiro = DataUtil.inicioPeriodo(pausa.inicio, frequencia: frequencia)
            var periodo: String? = DataUtil.inicioPeriodo(pausa.fim, frequencia: frequencia)
            while let p = periodo, p >= primeiro {   // "yyyy-MM-dd" compara certo como texto
                pausados.insert(p)
                periodo = DataUtil.periodoAnterior(a: p, frequencia: frequencia)
            }
        }
        return pausados
    }

    // Histórico com um registro por período (dia, semana ou mês), indexado pelo início do período.
    // Registros antigos gravados por dia — ou de antes de mudar a frequência — caem no período
    // que os contém; vale o mais recente, já que o histórico vem do mais novo pro mais antigo.
    private var porPeriodo: [String: HistoricoDia] {
        var resultado: [String: HistoricoDia] = [:]
        for registro in historico {
            let periodo = DataUtil.inicioPeriodo(registro.data, frequencia: frequencia)
            if resultado[periodo] == nil {
                resultado[periodo] = registro
            }
        }
        return resultado
    }

    // Sequência atual de períodos seguidos com 100% das tarefas concluídas.
    // O período atual só entra se já estiver completo — enquanto está em andamento, conta a partir do anterior.
    // Um período sem registro (app não aberto) quebra a sequência.
    // Período pausado é neutro: conta se foi completado, senão é pulado sem quebrar.
    var streakAtual: Int {
        let completos = Set(porPeriodo.filter { $0.value.completoNoDia }.keys)
        return Self.calcularStreak(completos: completos, pausados: periodosPausados, frequencia: frequencia)
    }

    // `completos` e `pausados` são inícios de período
    static func calcularStreak(completos: Set<String>, pausados: Set<String>,
                               frequencia: String, hoje: String = DataUtil.hoje()) -> Int {
        let atual = DataUtil.periodoAtual(frequencia: frequencia, hoje: hoje)

        var periodo: String? = completos.contains(atual) ? atual : DataUtil.periodoAnterior(a: atual, frequencia: frequencia)
        var streak = 0
        while let p = periodo {
            if completos.contains(p) {
                streak += 1
            } else if !pausados.contains(p) {
                break
            }
            periodo = DataUtil.periodoAnterior(a: p, frequencia: frequencia)
        }
        return streak
    }

    // Percentual médio de conclusão entre os períodos registrados.
    // Períodos pausados e não completados ficam de fora, pra pausa não puxar a média pra baixo.
    var percentualMedio: Double {
        let registros = porPeriodo
            .filter { periodo, registro in registro.completoNoDia || !periodosPausados.contains(periodo) }
            .values
        guard !registros.isEmpty else { return 0 }
        let soma = registros.reduce(0.0) { $0 + $1.percentual }
        return soma / Double(registros.count)
    }

    var periodosRegistrados: Int {
        porPeriodo.count
    }

    // Os 7 períodos até o atual, do mais antigo pro mais recente (pra desenhar da esquerda pra direita).
    // Cada item tem `data` = início do período. Períodos sem registro entram com id nil e 0 tarefas.
    var ultimos7Periodos: [HistoricoDia] {
        let registros = porPeriodo

        var periodos: [String] = [DataUtil.periodoAtual(frequencia: frequencia)]
        while periodos.count < 7,
              let anterior = DataUtil.periodoAnterior(a: periodos[periodos.count - 1], frequencia: frequencia) {
            periodos.append(anterior)
        }

        return periodos.reversed().map { periodo in
            guard let registro = registros[periodo] else {
                return HistoricoDia(id: nil, rotinaId: rotinaId, data: periodo, totalTarefas: 0, tarefasConcluidas: 0)
            }
            var normalizado = registro
            normalizado.data = periodo
            return normalizado
        }
    }
}
