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

    // Maior sequência que a rotina já teve (o "recorde"), com a mesma regra do streak
    var recorde: Int {
        let completos = Set(porPeriodo.filter { $0.value.completoNoDia }.keys)
        return Self.calcularRecorde(completos: completos, pausados: periodosPausados, frequencia: frequencia)
    }

    var periodosCompletos: Int {
        porPeriodo.values.filter(\.completoNoDia).count
    }

    // Percorre os períodos completos do mais antigo pro mais novo: cada um continua a sequência
    // se o período completo anterior vem logo antes dele (pulando períodos pausados).
    static func calcularRecorde(completos: Set<String>, pausados: Set<String>, frequencia: String) -> Int {
        var melhor = 0
        var atual = 0
        var ultimo: String?
        for periodo in completos.sorted() {
            var anterior = DataUtil.periodoAnterior(a: periodo, frequencia: frequencia)
            while let a = anterior, pausados.contains(a), !completos.contains(a) {
                anterior = DataUtil.periodoAnterior(a: a, frequencia: frequencia)
            }
            atual = (anterior != nil && anterior == ultimo) ? atual + 1 : 1
            melhor = max(melhor, atual)
            ultimo = periodo
        }
        return melhor
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

    // MARK: - Mapa de calor

    // Uma célula por período dos últimos 12 meses, do mais antigo pro mais recente
    var mapaDeCalor: [CelulaMapa] {
        let registros = porPeriodo
        return Self.periodosUltimoAno(frequencia: frequencia).map { periodo in
            let registro = registros[periodo]
            return CelulaMapa(
                periodo: periodo,
                percentual: registro.map(\.percentual),
                completo: registro?.completoNoDia ?? false,
                pausado: periodosPausados.contains(periodo)
            )
        }
    }

    var periodosCompletosNoAno: Int {
        mapaDeCalor.filter(\.completo).count
    }

    // Inícios de período dos últimos 12 meses, do mais antigo pro mais recente.
    // Diária: 365 dias, recuando até o domingo pra a grade começar alinhada na primeira linha.
    // Semanal: 52 semanas. Mensal: 12 meses.
    static func periodosUltimoAno(frequencia: String, hoje: String = DataUtil.hoje()) -> [String] {
        let atual = DataUtil.periodoAtual(frequencia: frequencia, hoje: hoje)
        var periodos = [atual]

        switch frequencia {
        case "Semanal", "Mensal":
            let quantidade = frequencia == "Semanal" ? 52 : 12
            while periodos.count < quantidade,
                  let anterior = DataUtil.periodoAnterior(a: periodos[periodos.count - 1], frequencia: frequencia) {
                periodos.append(anterior)
            }
        default:
            // Recua 364 dias e depois até o domingo daquela semana
            var inicio = atual
            for _ in 0..<364 {
                inicio = DataUtil.diaAnterior(a: inicio) ?? inicio
            }
            inicio = DataUtil.inicioPeriodo(inicio, frequencia: "Semanal")
            while let anterior = DataUtil.diaAnterior(a: periodos[periodos.count - 1]), anterior >= inicio {
                periodos.append(anterior)
            }
        }
        return periodos.reversed()
    }
}

struct CelulaMapa: Identifiable {
    let periodo: String        // início do período ("yyyy-MM-dd")
    let percentual: Double?    // nil = sem registro
    let completo: Bool
    let pausado: Bool

    var id: String { periodo }
}
