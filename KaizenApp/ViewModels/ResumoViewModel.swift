import Foundation
import Combine

class ResumoViewModel: ObservableObject {
    @Published var rotinas: [ResumoRotina] = []
    @Published var semana: [DiaSemana] = []
    @Published var melhorSequenciaAtual = 0
    @Published var premios: [Premio] = []

    func carregar() {
        rotinas = ResumoWidget.carregar()

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
        semana = Self.ultimosDias(historicoDiario: historicoDiario).map { dia in
            guard dia.ehHoje, let hoje = Self.progresso(rotinas, frequencia: "Diária"), hoje.total > 0 else { return dia }
            return DiaSemana(data: dia.data, progresso: Double(hoje.feitas) / Double(hoje.total),
                             futuro: false, ehHoje: true)
        }
        premios = Premio.calcular(recordes: recordes, totalCompletos: totalCompletos)
    }

    var premiosConquistados: Int { premios.filter(\.conquistado).count }

    static func progresso(_ rotinas: [ResumoRotina], frequencia: String, agora: Date = .now) -> (feitas: Int, total: Int)? {
        let daFrequencia = rotinas.filter { $0.frequencia == frequencia && $0.total > 0 && $0.programadaHoje }
        guard !daFrequencia.isEmpty else { return nil }
        return (daFrequencia.reduce(0) { $0 + $1.concluidas(em: agora) }, daFrequencia.reduce(0) { $0 + $1.total })
    }

    static func ultimosDias(historicoDiario: [HistoricoDia], hoje: String = DataUtil.hoje(), quantidade: Int = 7) -> [DiaSemana] {
        let calendario = Calendar(identifier: .gregorian)
        guard let dataHoje = DataUtil.data(de: hoje) else { return [] }
        let dias = (0..<quantidade).reversed().compactMap { atras in
            calendario.date(byAdding: .day, value: -atras, to: dataHoje).map(DataUtil.string(de:))
        }

        return dias.map { dia in
            let registros = historicoDiario.filter { $0.data == dia }
            let total = registros.reduce(0) { $0 + $1.totalTarefas }
            let feitas = registros.reduce(0) { $0 + $1.tarefasConcluidas }
            return DiaSemana(
                data: dia,
                progresso: total > 0 ? Double(feitas) / Double(total) : nil,
                futuro: false,
                ehHoje: dia == hoje
            )
        }
    }
}

struct DiaSemana: Identifiable {
    let data: String
    let progresso: Double?
    let futuro: Bool
    let ehHoje: Bool
    var id: String { data }
}

struct Premio: Identifiable {
    let id: String
    let titulo: String
    let descricao: String
    let simbolo: String
    let conquistado: Bool
    let grupo: Grupo

    enum Grupo: String, CaseIterable {
        case total = "Constância"
        case sequencia = "Sequências"
    }

    static let marcosSequencia = [3, 7, 14, 30, 60, 100, 365]
    static let marcosTotal = [1, 10, 50, 100, 250, 500]

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
