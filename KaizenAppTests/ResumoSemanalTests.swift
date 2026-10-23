import Foundation
import Testing
@testable import KaizenApp

// Semana de domingo 11/10 a sábado 17/10 de 2026; a anterior é 04/10 a 10/10
@MainActor
struct ResumoSemanalTests {
    private func dia(_ data: String, _ feitas: Int, de total: Int) -> HistoricoDia {
        HistoricoDia(id: 1, rotinaId: 1, data: data, totalTarefas: total, tarefasConcluidas: feitas)
    }

    private var manha: DadosRotinaSemana {
        // Completa em 4 dos 7 dias; parcial no dia 16
        DadosRotinaSemana(nome: "Manhã", icone: "☀️", frequencia: "Diária", historico: [
            dia("2026-10-11", 2, de: 2), dia("2026-10-12", 2, de: 2), dia("2026-10-13", 2, de: 2),
            dia("2026-10-15", 2, de: 2), dia("2026-10-16", 1, de: 2),
            dia("2026-10-05", 2, de: 2),   // semana anterior: 1 de 7
        ])
    }

    private var faxina: DadosRotinaSemana {
        // Semanal: registro gravado no domingo da semana
        DadosRotinaSemana(nome: "Faxina", icone: "🧹", frequencia: "Semanal",
                          historico: [dia("2026-10-11", 3, de: 3)])
    }

    @Test func taxaContaDiasESemanas() {
        let resumo = ResumoSemanal.calcular(rotinas: [manha, faxina], inicioSemana: "2026-10-11")
        // 4 dias completos + 1 semana completa, de 7 + 1 possíveis
        #expect(resumo.taxa == 5.0 / 8.0)
        #expect(resumo.inicio == "2026-10-11")
        #expect(resumo.fim == "2026-10-17")
    }

    @Test func diasPerfeitosETarefas() {
        let resumo = ResumoSemanal.calcular(rotinas: [manha, faxina], inicioSemana: "2026-10-11")
        #expect(resumo.diasPerfeitos == 4)
        #expect(resumo.tarefasFeitas == 2 + 2 + 2 + 2 + 1 + 3)
    }

    @Test func linhasPorRotina() {
        let resumo = ResumoSemanal.calcular(rotinas: [manha, faxina], inicioSemana: "2026-10-11")
        #expect(resumo.linhas[0].dias == [true, true, true, false, true, false, false])
        #expect(resumo.linhas[1].semanaCompleta)
    }

    @Test func melhorDiaEmpataNoMaisCedo() {
        let resumo = ResumoSemanal.calcular(rotinas: [manha], inicioSemana: "2026-10-11")
        #expect(resumo.melhorDia == "2026-10-11")
    }

    @Test func comparaComASemanaAnterior() {
        let resumo = ResumoSemanal.calcular(rotinas: [manha], inicioSemana: "2026-10-11")
        // 4/7 agora contra 1/7 antes
        #expect(abs((resumo.variacao ?? 0) - 3.0 / 7.0) < 0.0001)
    }

    @Test func mensaisFicamDeFora() {
        let financas = DadosRotinaSemana(nome: "Finanças", icone: "💰", frequencia: "Mensal",
                                         historico: [dia("2026-10-01", 4, de: 4)])
        let resumo = ResumoSemanal.calcular(rotinas: [financas], inicioSemana: "2026-10-11")
        #expect(resumo.vazio)
        #expect(resumo.taxa == 0)
        #expect(resumo.variacao == nil)
    }

    @Test func semanaPassadaEhODomingoAnterior() {
        // Terça 20/10: a semana atual começa no domingo 18; a passada, no 11
        #expect(ResumoSemanalViewModel.semanaPassada(hoje: "2026-10-20") == "2026-10-11")
        // No próprio domingo, a passada é a que acabou ontem
        #expect(ResumoSemanalViewModel.semanaPassada(hoje: "2026-10-18") == "2026-10-11")
    }

    @Test func rotinaSemTarefasOuCriadaDepoisNaoConta() {
        let semTarefas = DadosRotinaSemana(nome: "Vazia", icone: "📋", frequencia: "Diária",
                                           historico: [dia("2026-10-12", 0, de: 0)])
        let criadaDepois = DadosRotinaSemana(nome: "Nova", icone: "💪", frequencia: "Diária",
                                             historico: [dia("2026-10-22", 1, de: 4)])
        let resumo = ResumoSemanal.calcular(rotinas: [manha, semTarefas, criadaDepois], inicioSemana: "2026-10-11")
        #expect(resumo.linhas.map(\.nome) == ["Manhã"])
        #expect(resumo.taxa == 4.0 / 7.0)
        #expect(resumo.diasPerfeitos == 4)
    }
}
