import Foundation
import Combine

// Dados da aba Resumo: os três anéis, a semana, a sequência e os prêmios
class ResumoViewModel: ObservableObject {
    @Published var rotinas: [ResumoRotina] = []
    @Published var semana: [DiaSemana] = []
    @Published var melhorSequenciaAtual = 0
    @Published var premios: [Premio] = []

    func carregar() {
        rotinas = ResumoWidget.carregar()

        // Estatísticas de cada rotina ativa (streak, recorde, períodos completos)
        var sequencias: [Int] = []
        var recordes: [Int] = []
        var totalCompletos = 0
        var historicoDiario: [HistoricoDia] = []
        for rotina in RotinaDAO().listarTodas() where rotina.ativa {
            guard let id = rotina.id else { continue }
            let estatisticas = EstatisticasViewModel(rotinaId: id, frequencia: rotina.frequencia, diasSemana: rotina.diasSemana)
            estatisticas.carregar()
            sequencias.append(estatisticas.streakAtual)
            recordes.append(estatisticas.recorde)
            totalCompletos += estatisticas.periodosCompletos
            if rotina.frequencia == "Diária" {
                historicoDiario += estatisticas.historico
            }
        }

        melhorSequenciaAtual = sequencias.max() ?? 0
        // Hoje usa o progresso ao vivo das rotinas diárias (o histórico pode estar um passo atrás)
        semana = Self.semanaAtual(historicoDiario: historicoDiario).map { dia in
            guard dia.ehHoje, let hoje = Self.progresso(rotinas, frequencia: "Diária"), hoje.total > 0 else { return dia }
            return DiaSemana(data: dia.data, progresso: Double(hoje.feitas) / Double(hoje.total),
                             futuro: false, ehHoje: true)
        }
        premios = Premio.calcular(recordes: recordes, totalCompletos: totalCompletos)
    }

    var premiosConquistados: Int { premios.filter(\.conquistado).count }

    // MARK: - Anéis

    // Fração de tarefas feitas nas rotinas de uma frequência (nil = nenhuma rotina dessa frequência)
    static func progresso(_ rotinas: [ResumoRotina], frequencia: String, agora: Date = .now) -> (feitas: Int, total: Int)? {
        // Rotinas de folga hoje ficam fora dos anéis
        let daFrequencia = rotinas.filter { $0.frequencia == frequencia && $0.total > 0 && $0.programadaHoje }
        guard !daFrequencia.isEmpty else { return nil }
        return (daFrequencia.reduce(0) { $0 + $1.concluidas(em: agora) }, daFrequencia.reduce(0) { $0 + $1.total })
    }

    func fracao(_ frequencia: String) -> Double {
        guard let p = Self.progresso(rotinas, frequencia: frequencia), p.total > 0 else { return 0 }
        return Double(p.feitas) / Double(p.total)
    }

    // MARK: - Semana

    // Os 7 dias da semana atual (domingo a sábado), com o progresso das rotinas diárias em cada dia
    static func semanaAtual(historicoDiario: [HistoricoDia], hoje: String = DataUtil.hoje()) -> [DiaSemana] {
        let domingo = DataUtil.inicioPeriodo(hoje, frequencia: "Semanal")
        var dias = [domingo]
        while dias.count < 7, let data = DataUtil.data(de: dias[dias.count - 1]),
              let seguinte = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: data) {
            dias.append(DataUtil.string(de: seguinte))
        }

        return dias.map { dia in
            let registros = historicoDiario.filter { $0.data == dia }
            let total = registros.reduce(0) { $0 + $1.totalTarefas }
            let feitas = registros.reduce(0) { $0 + $1.tarefasConcluidas }
            return DiaSemana(
                data: dia,
                progresso: total > 0 ? Double(feitas) / Double(total) : nil,
                futuro: dia > hoje,
                ehHoje: dia == hoje
            )
        }
    }
}

struct DiaSemana: Identifiable {
    let data: String
    let progresso: Double?   // nil = sem registro
    let futuro: Bool
    let ehHoje: Bool
    var id: String { data }
}

// MARK: - Prêmios

struct Premio: Identifiable {
    let id: String
    let titulo: String
    let descricao: String
    let simbolo: String      // SF Symbol
    let conquistado: Bool
    let grupo: Grupo

    enum Grupo: String, CaseIterable {
        case total = "Constância"
        case sequencia = "Sequências"
    }

    static let marcosSequencia = [3, 7, 14, 30, 60, 100, 365]
    static let marcosTotal = [1, 10, 50, 100, 250, 500]

    // Sequência: o recorde de qualquer rotina (em dias, semanas ou meses, conforme a rotina).
    // Constância: soma dos períodos completos de todas as rotinas.
    static func calcular(recordes: [Int], totalCompletos: Int) -> [Premio] {
        let melhorRecorde = recordes.max() ?? 0
        let sequencias = marcosSequencia.map { marco in
            Premio(id: "seq-\(marco)", titulo: "\(marco) seguidas",
                   descricao: "Completar uma rotina \(marco) vezes seguidas",
                   simbolo: "flame.fill", conquistado: melhorRecorde >= marco, grupo: .sequencia)
        }
        let totais = marcosTotal.map { marco in
            Premio(id: "tot-\(marco)", titulo: marco == 1 ? "Primeiro passo" : "\(marco) completas",
                   descricao: marco == 1 ? "Completar uma rotina pela primeira vez" : "Completar rotinas \(marco) vezes no total",
                   simbolo: marco == 1 ? "figure.walk" : "checkmark.seal.fill",
                   conquistado: totalCompletos >= marco, grupo: .total)
        }
        return totais + sequencias
    }
}
