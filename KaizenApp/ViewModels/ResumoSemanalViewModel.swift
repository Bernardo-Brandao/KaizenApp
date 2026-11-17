import Foundation
import Combine

struct DadosRotinaSemana {
    let nome: String
    let icone: String
    let frequencia: String
    let historico: [HistoricoDia]
    var diasSemana: Set<Int> = []
    var pulados: Set<String> = []

    func completo(_ dia: String) -> Bool {
        historico.contains { $0.data == dia && $0.completoNoDia }
    }

    func conta(_ dia: String) -> Bool {
        DiasSemana.inclui(diasSemana, dia: dia) && (completo(dia) || !pulados.contains(dia))
    }
}

struct ResumoSemanal {
    struct Linha: Identifiable {
        let nome: String
        let icone: String
        let frequencia: String
        let dias: [Bool?]
        let semanaCompleta: Bool
        var id: String { nome }
    }

    let inicio: String
    let fim: String
    let taxa: Double
    let diasPerfeitos: Int
    let tarefasFeitas: Int
    let melhorDia: String?
    let variacao: Double?
    let linhas: [Linha]

    var vazio: Bool { linhas.isEmpty }

    static func calcular(rotinas: [DadosRotinaSemana], inicioSemana: String) -> ResumoSemanal {
        let dias = diasDaSemana(inicioSemana)
        let atual = taxaETotais(rotinas: rotinas, dias: dias, inicioSemana: inicioSemana)

        let variacao: Double?
        if let anterior = DataUtil.periodoAnterior(a: inicioSemana, frequencia: "Semanal"), atual.possiveis > 0 {
            let passada = taxaETotais(rotinas: rotinas, dias: diasDaSemana(anterior), inicioSemana: anterior)
            variacao = passada.possiveis > 0 ? atual.taxa - passada.taxa : nil
        } else {
            variacao = nil
        }

        return ResumoSemanal(
            inicio: inicioSemana,
            fim: dias.last ?? inicioSemana,
            taxa: atual.taxa,
            diasPerfeitos: atual.diasPerfeitos,
            tarefasFeitas: atual.tarefasFeitas,
            melhorDia: atual.melhorDia,
            variacao: variacao,
            linhas: atual.linhas
        )
    }

    private static func diasDaSemana(_ domingo: String) -> [String] {
        var dias = [domingo]
        let calendario = Calendar(identifier: .gregorian)
        while dias.count < 7, let data = DataUtil.data(de: dias[dias.count - 1]),
              let seguinte = calendario.date(byAdding: .day, value: 1, to: data) {
            dias.append(DataUtil.string(de: seguinte))
        }
        return dias
    }

    private static func taxaETotais(rotinas: [DadosRotinaSemana], dias: [String], inicioSemana: String)
        -> (taxa: Double, possiveis: Int, diasPerfeitos: Int, tarefasFeitas: Int, melhorDia: String?, linhas: [Linha]) {
        var completos = 0
        var possiveis = 0
        var tarefasFeitas = 0
        var linhas: [Linha] = []
        var percentuaisPorDia: [String: [Double]] = [:]

        let fim = dias.last ?? inicioSemana
        let participantes = rotinas.filter { rotina in
            rotina.historico.contains { $0.totalTarefas > 0 && $0.data <= fim }
        }
        let diarias = participantes.filter { $0.frequencia == "Diária" }

        for rotina in participantes {
            switch rotina.frequencia {
            case "Diária":
                let porDia = Dictionary(rotina.historico.map { ($0.data, $0) }, uniquingKeysWith: { a, _ in a })
                let programados = dias.filter(rotina.conta)
                let feitos: [Bool?] = dias.map { dia in rotina.conta(dia) ? rotina.completo(dia) : nil }
                for dia in programados {
                    if let registro = porDia[dia] {
                        tarefasFeitas += registro.tarefasConcluidas
                        percentuaisPorDia[dia, default: []].append(registro.percentual)
                    }
                }
                completos += feitos.filter { $0 == true }.count
                possiveis += programados.count
                linhas.append(Linha(nome: rotina.nome, icone: rotina.icone, frequencia: rotina.frequencia,
                                    dias: feitos, semanaCompleta: false))
            case "Semanal":
                let registro = rotina.historico
                    .filter { DataUtil.inicioPeriodo($0.data, frequencia: "Semanal") == inicioSemana }
                    .max { $0.data < $1.data }
                let completa = registro?.completoNoDia ?? false
                tarefasFeitas += registro?.tarefasConcluidas ?? 0
                completos += completa ? 1 : 0
                if completa || !rotina.pulados.contains(inicioSemana) { possiveis += 1 }
                linhas.append(Linha(nome: rotina.nome, icone: rotina.icone, frequencia: rotina.frequencia,
                                    dias: [], semanaCompleta: completa))
            default:
                continue
            }
        }

        let diasPerfeitos = dias.filter { dia in
            let doDia = diarias.filter { $0.conta(dia) }
            return !doDia.isEmpty && doDia.allSatisfy { $0.completo(dia) }
        }.count
        let melhorDia = dias
            .compactMap { dia -> (String, Double)? in
                guard let valores = percentuaisPorDia[dia], !valores.isEmpty else { return nil }
                return (dia, valores.reduce(0, +) / Double(valores.count))
            }
            .filter { $0.1 > 0 }
            .max { $0.1 < $1.1 || ($0.1 == $1.1 && $0.0 > $1.0) }?.0

        return (possiveis == 0 ? 0 : Double(completos) / Double(possiveis), possiveis,
                diasPerfeitos, tarefasFeitas, melhorDia, linhas)
    }
}

class ResumoSemanalViewModel: ObservableObject {
    @Published var resumo: ResumoSemanal?

    static func semanaPassada(hoje: String = DataUtil.hoje()) -> String {
        let atual = DataUtil.periodoAtual(frequencia: "Semanal", hoje: hoje)
        return DataUtil.periodoAnterior(a: atual, frequencia: "Semanal") ?? atual
    }

    func carregar() {
        let historicoDao = HistoricoDAO()
        let puloDao = PuloDAO()
        let rotinas = RotinaDAO().listarTodas().compactMap { rotina -> DadosRotinaSemana? in
            guard rotina.ativa, let id = rotina.id else { return nil }
            return DadosRotinaSemana(nome: rotina.nome, icone: rotina.iconeExibido,
                                     frequencia: rotina.frequencia, historico: historicoDao.listarPorRotina(id),
                                     diasSemana: rotina.diasSemana, pulados: puloDao.periodos(rotinaId: id))
        }
        resumo = ResumoSemanal.calcular(rotinas: rotinas, inicioSemana: Self.semanaPassada())
    }
}
