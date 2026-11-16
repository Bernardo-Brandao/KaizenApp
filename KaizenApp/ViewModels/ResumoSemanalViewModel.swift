import Foundation
import Combine

// O que entra no cálculo de cada rotina
struct DadosRotinaSemana {
    let nome: String
    let icone: String
    let frequencia: String
    let historico: [HistoricoDia]
    var diasSemana: Set<Int> = []   // diária com dias escolhidos: os outros são folga
    var pulados: Set<String> = []   // dias (ou semanas) que a pessoa pulou — contam como folga

    // A rotina foi completada nesse dia?
    func completo(_ dia: String) -> Bool {
        historico.contains { $0.data == dia && $0.completoNoDia }
    }

    // O dia conta pra rotina? Não conta se for folga, nem se foi pulado e não chegou a ser completado
    func conta(_ dia: String) -> Bool {
        DiasSemana.inclui(diasSemana, dia: dia) && (completo(dia) || !pulados.contains(dia))
    }
}

// Como foi uma semana (domingo a sábado). Rotinas mensais ficam de fora.
struct ResumoSemanal {
    struct Linha: Identifiable {
        let nome: String
        let icone: String
        let frequencia: String
        let dias: [Bool?]       // diária: 7 posições (domingo…sábado); true = completa, nil = folga
        let semanaCompleta: Bool // semanal: a semana foi completada
        var id: String { nome }
    }

    let inicio: String               // domingo
    let fim: String                  // sábado
    let taxa: Double                 // 0…1: períodos completos / períodos possíveis
    let diasPerfeitos: Int           // dias com todas as rotinas diárias completas
    let tarefasFeitas: Int
    let melhorDia: String?           // "yyyy-MM-dd" do dia com maior conclusão
    let variacao: Double?            // taxa desta semana − taxa da anterior (nil sem rotinas)
    let linhas: [Linha]

    var vazio: Bool { linhas.isEmpty }

    // MARK: - Cálculo (puro, testável)

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

        // Só entram rotinas que já tinham tarefas até o fim da semana: uma rotina sem tarefas,
        // ou criada depois, não tem como ter sido cumprida e só puxaria a taxa pra baixo
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
                // nil = folga ou dia pulado (aparece só com o contorno, não conta)
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
                // Registro mais recente que cai nessa semana (vale também pra histórico antigo gravado por dia)
                let registro = rotina.historico
                    .filter { DataUtil.inicioPeriodo($0.data, frequencia: "Semanal") == inicioSemana }
                    .max { $0.data < $1.data }
                let completa = registro?.completoNoDia ?? false
                tarefasFeitas += registro?.tarefasConcluidas ?? 0
                completos += completa ? 1 : 0
                // Semana pulada e não feita não conta como possível
                if completa || !rotina.pulados.contains(inicioSemana) { possiveis += 1 }
                linhas.append(Linha(nome: rotina.nome, icone: rotina.icone, frequencia: rotina.frequencia,
                                    dias: [], semanaCompleta: completa))
            default:
                continue   // mensais ficam de fora
            }
        }

        // Dia perfeito: todas as diárias que contavam no dia foram completadas (e havia alguma)
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
            .max { $0.1 < $1.1 || ($0.1 == $1.1 && $0.0 > $1.0) }?.0   // empate: o dia mais cedo

        return (possiveis == 0 ? 0 : Double(completos) / Double(possiveis), possiveis,
                diasPerfeitos, tarefasFeitas, melhorDia, linhas)
    }
}

class ResumoSemanalViewModel: ObservableObject {
    @Published var resumo: ResumoSemanal?

    // A última semana que terminou: o domingo anterior ao desta semana
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
