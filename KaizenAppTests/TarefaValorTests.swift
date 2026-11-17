import Foundation
import Testing
@testable import KaizenApp

@MainActor
struct TarefaValorTests {
    private func agua(meta: Double?, valor: Double) -> Tarefa {
        Tarefa(id: 1, rotinaId: 1, nome: "Água", ordem: 0, concluidaHoje: false,
               tipo: "valor", unidade: "L", meta: meta, valorAtual: valor)
    }

    @Test func comMetaSoFicaFeitaAoBaterAMeta() {
        let tarefa = agua(meta: 3, valor: 0)
        #expect(!tarefa.atingiu(2.5))
        #expect(tarefa.atingiu(3))
        #expect(tarefa.atingiu(3.5))
    }

    @Test func semMetaQualquerValorConta() {
        let tarefa = agua(meta: nil, valor: 0)
        #expect(!tarefa.atingiu(0))
        #expect(tarefa.atingiu(0.25))
    }

    @Test func textoEProgresso() {
        #expect(agua(meta: 3, valor: 1.5).valorDescrito == "1,5 / 3 L")
        #expect(agua(meta: 3, valor: 0).valorDescrito == "— / 3 L")
        #expect(agua(meta: nil, valor: 2).valorDescrito == "2 L")
        #expect(agua(meta: 3, valor: 1.5).progressoValor == 0.5)
        #expect(agua(meta: 3, valor: 4).progressoValor == 1)
        #expect(agua(meta: nil, valor: 1).progressoValor == 1)
    }

    @Test func numerosNoFormatoBrasileiro() {
        #expect(NumeroUtil.formatar(1.5) == "1,5")
        #expect(NumeroUtil.formatar(3) == "3")
        #expect(NumeroUtil.formatar(0.25) == "0,25")
        #expect(NumeroUtil.ler("1,5") == 1.5)
        #expect(NumeroUtil.ler("1.5") == 1.5)
        #expect(NumeroUtil.ler(" 2 ") == 2)
        #expect(NumeroUtil.ler("") == nil)
        #expect(NumeroUtil.ler("abc") == nil)
    }

    @Test func tarefaDeMarcarNaoEhValor() {
        let tarefa = Tarefa(id: 2, rotinaId: 1, nome: "Alongar", ordem: 1, concluidaHoje: false)
        #expect(!tarefa.ehValor)
        #expect(tarefa.tipo == "check")
    }
}

@MainActor
struct ContagemTests {
    private func academia(_ feitas: Double, meta: Double? = 3) -> Tarefa {
        Tarefa(id: 1, rotinaId: 1, nome: "Academia", ordem: 0, concluidaHoje: false,
               tipo: "vezes", meta: meta, valorAtual: feitas)
    }

    @Test func contagemEhUmTipoDeValor() {
        #expect(academia(0).ehValor && academia(0).ehContagem)
    }

    @Test func descreveAsVezes() {
        #expect(academia(1).valorDescrito == "1 de 3 vezes")
        #expect(academia(1, meta: 1).valorDescrito == "1 de 1 vez")
        #expect(academia(2, meta: nil).valorDescrito == "2 vezes")
    }

    @Test func ficaFeitaAoBaterAMeta() {
        #expect(!academia(0).atingiu(2))
        #expect(academia(0).atingiu(3))
    }
}

@MainActor
struct SaudeTests {
    private var calendario: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        return c
    }

    @Test func soSobeOValor() {
        #expect(SaudeService.deveAtualizar(atual: 0, saude: 5200))
        #expect(!SaudeService.deveAtualizar(atual: 2.5, saude: 2))
        #expect(!SaudeService.deveAtualizar(atual: 2, saude: 2.0001))
    }

    @Test func sonoContaDesdeAs18hDeOntem() {
        let agora = calendario.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 9))!
        let inicio = SaudeService.inicioDaLeitura(.sono, frequencia: "Diária", agora: agora, calendario: calendario)
        #expect(inicio == calendario.date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 18)))
        let passos = SaudeService.inicioDaLeitura(.passos, frequencia: "Diária", agora: agora, calendario: calendario)
        #expect(passos == calendario.date(from: DateComponents(year: 2026, month: 10, day: 28)))
    }

    @Test func passosNaSemanaContamDesdeDomingo() {
        let quarta = calendario.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 9))!
        let inicio = SaudeService.inicioDaLeitura(.passos, frequencia: "Semanal", agora: quarta, calendario: calendario)
        #expect(inicio == calendario.date(from: DateComponents(year: 2026, month: 10, day: 25)))
    }

    @Test func sonoSobrepostoNaoContaDuasVezes() {
        let base = Date(timeIntervalSince1970: 0)
        let h = { (x: Double) in base.addingTimeInterval(x * 3600) }
        #expect(SaudeService.duracaoSemSobreposicao([(h(23), h(31)), (h(25), h(32))]) == 9 * 3600)
    }
}
