import Foundation
import Testing
@testable import KaizenApp

// Cálculos do redesign: recorde, anéis por frequência, semana e prêmios ("hoje" = terça 2026-10-20)
@MainActor
struct ResumoTests {
    let hoje = "2026-10-20"

    // MARK: - Recorde

    @Test func recordeEhAMaiorSequenciaDoHistorico() {
        // 3 seguidos (01–03), buraco, 2 seguidos (05–06)
        let completos: Set = ["2026-10-01", "2026-10-02", "2026-10-03", "2026-10-05", "2026-10-06"]
        #expect(EstatisticasViewModel.calcularRecorde(completos: completos, pausados: [], frequencia: "Diária") == 3)
    }

    @Test func recordeAtravessaPausa() {
        let completos: Set = ["2026-10-01", "2026-10-02", "2026-10-05"]
        let pausados: Set = ["2026-10-03", "2026-10-04"]
        #expect(EstatisticasViewModel.calcularRecorde(completos: completos, pausados: pausados, frequencia: "Diária") == 3)
    }

    @Test func recordeSemanal() {
        let completos: Set = ["2026-09-20", "2026-09-27", "2026-10-04", "2026-10-18"]
        #expect(EstatisticasViewModel.calcularRecorde(completos: completos, pausados: [], frequencia: "Semanal") == 3)
    }

    @Test func recordeVazio() {
        #expect(EstatisticasViewModel.calcularRecorde(completos: [], pausados: [], frequencia: "Diária") == 0)
    }

    // MARK: - Anéis por frequência

    private func rotina(_ id: Int64, _ frequencia: String, feitas: Int, total: Int) -> ResumoRotina {
        let tarefas = (0..<total).map { ResumoTarefa(id: id * 10 + Int64($0), nome: "T", concluida: $0 < feitas) }
        return ResumoRotina(id: id, nome: "R\(id)", tarefas: tarefas, corHex: nil, validoAte: .distantFuture, frequencia: frequencia)
    }

    @Test func progressoSomaAsTarefasDaFrequencia() {
        let rotinas = [rotina(1, "Diária", feitas: 1, total: 3), rotina(2, "Diária", feitas: 2, total: 2),
                       rotina(3, "Semanal", feitas: 0, total: 4)]
        let hoje = ResumoViewModel.progresso(rotinas, frequencia: "Diária")
        #expect(hoje?.feitas == 3)
        #expect(hoje?.total == 5)
        #expect(ResumoViewModel.progresso(rotinas, frequencia: "Semanal")?.feitas == 0)
        #expect(ResumoViewModel.progresso(rotinas, frequencia: "Mensal") == nil)
    }

    // MARK: - Semana

    @Test func semanaVaiDeDomingoASabado() {
        let historico = [HistoricoDia(id: 1, rotinaId: 1, data: "2026-10-19", totalTarefas: 4, tarefasConcluidas: 2)]
        let semana = ResumoViewModel.semanaAtual(historicoDiario: historico, hoje: hoje)
        #expect(semana.map(\.data) == ["2026-10-18", "2026-10-19", "2026-10-20", "2026-10-21",
                                       "2026-10-22", "2026-10-23", "2026-10-24"])
        #expect(semana[1].progresso == 0.5)
        #expect(semana[0].progresso == nil)          // sem registro
        #expect(semana[2].ehHoje)
        #expect(semana[3].futuro && !semana[2].futuro)
    }

    // MARK: - Prêmios

    @Test func premiosConquistadosPelosMarcos() {
        let premios = Premio.calcular(recordes: [8, 2], totalCompletos: 12)
        let conquistados = Set(premios.filter(\.conquistado).map(\.id))
        #expect(conquistados == ["tot-1", "tot-10", "seq-3", "seq-7"])
    }

    @Test func nenhumPremioNoComeco() {
        #expect(Premio.calcular(recordes: [], totalCompletos: 0).allSatisfy { !$0.conquistado })
    }
}
