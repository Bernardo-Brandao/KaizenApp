import Foundation
import Combine

class EstatisticasViewModel: ObservableObject {
    @Published var historico: [HistoricoDia] = []
    @Published var periodosPausados: Set<String> = []
    private let dao = HistoricoDAO()
    private let rotinaId: Int64
    let frequencia: String
    let diasSemana: Set<Int>

    init(rotinaId: Int64, frequencia: String, diasSemana: Set<Int> = []) {
        self.rotinaId = rotinaId
        self.frequencia = frequencia
        self.diasSemana = diasSemana
    }

    static func ehFolga(_ periodo: String, frequencia: String, diasSemana: Set<Int>) -> Bool {
        frequencia == "Diária" && !DiasSemana.inclui(diasSemana, dia: periodo)
    }

    func carregar() {
        historico = dao.listarPorRotina(rotinaId)

        let pulados = PuloDAO().periodos(rotinaId: rotinaId).map { DataUtil.inicioPeriodo($0, frequencia: frequencia) }
        periodosPausados = Self.periodosPausados(PausaDAO().listar(rotinaId: rotinaId), frequencia: frequencia)
            .union(pulados)
    }

    static func periodosPausados(_ pausas: [(inicio: String, fim: String)], frequencia: String) -> Set<String> {
        var pausados: Set<String> = []
        for pausa in pausas {
            let primeiro = DataUtil.inicioPeriodo(pausa.inicio, frequencia: frequencia)
            var periodo: String? = DataUtil.inicioPeriodo(pausa.fim, frequencia: frequencia)
            while let p = periodo, p >= primeiro {
                pausados.insert(p)
                periodo = DataUtil.periodoAnterior(a: p, frequencia: frequencia)
            }
        }
        return pausados
    }

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

    var streakAtual: Int {
        let completos = Set(porPeriodo.filter { $0.value.completoNoDia }.keys)
        return Self.calcularStreak(completos: completos, pausados: periodosPausados, frequencia: frequencia,
                                   diasSemana: diasSemana)
    }

    static func calcularStreak(completos: Set<String>, pausados: Set<String>,
                               frequencia: String, hoje: String = DataUtil.hoje(),
                               diasSemana: Set<Int> = []) -> Int {
        let atual = DataUtil.periodoAtual(frequencia: frequencia, hoje: hoje)

        var periodo: String? = completos.contains(atual) ? atual : DataUtil.periodoAnterior(a: atual, frequencia: frequencia)
        var streak = 0
        while let p = periodo {
            if completos.contains(p) {
                streak += 1
            } else if !pausados.contains(p) && !ehFolga(p, frequencia: frequencia, diasSemana: diasSemana) {
                break
            }
            periodo = DataUtil.periodoAnterior(a: p, frequencia: frequencia)
        }
        return streak
    }

    var recorde: Int {
        let completos = Set(porPeriodo.filter { $0.value.completoNoDia }.keys)
        return Self.calcularRecorde(completos: completos, pausados: periodosPausados, frequencia: frequencia,
                                    diasSemana: diasSemana)
    }

    var periodosCompletos: Int {
        porPeriodo.values.filter(\.completoNoDia).count
    }

    static func calcularRecorde(completos: Set<String>, pausados: Set<String>, frequencia: String,
                                diasSemana: Set<Int> = []) -> Int {
        var melhor = 0
        var atual = 0
        var ultimo: String?
        for periodo in completos.sorted() {
            var anterior = DataUtil.periodoAnterior(a: periodo, frequencia: frequencia)
            while let a = anterior, !completos.contains(a),
                  pausados.contains(a) || ehFolga(a, frequencia: frequencia, diasSemana: diasSemana) {
                anterior = DataUtil.periodoAnterior(a: a, frequencia: frequencia)
            }
            atual = (anterior != nil && anterior == ultimo) ? atual + 1 : 1
            melhor = max(melhor, atual)
            ultimo = periodo
        }
        return melhor
    }

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
    let periodo: String
    let percentual: Double?
    let completo: Bool
    let pausado: Bool

    var id: String { periodo }
}
