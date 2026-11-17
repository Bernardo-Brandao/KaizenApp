import Testing
@testable import KaizenApp

@MainActor
struct StreakTests {
    let hoje = "2026-10-20"

    private func streak(_ completos: Set<String>, pausados: Set<String> = [], frequencia: String = "Diária") -> Int {
        EstatisticasViewModel.calcularStreak(completos: completos, pausados: pausados, frequencia: frequencia, hoje: hoje)
    }

    @Test func diaEmAndamentoNaoZeraOStreak() {
        #expect(streak(["2026-10-17", "2026-10-18", "2026-10-19"]) == 3)
    }

    @Test func hojeCompletoEntraNaConta() {
        #expect(streak(["2026-10-19", "2026-10-20"]) == 2)
    }

    @Test func diaPuladoQuebraASequencia() {
        #expect(streak(["2026-10-19", "2026-10-17"]) == 1)
    }

    @Test func semNadaCompletoEhZero() {
        #expect(streak([]) == 0)
    }

    @Test func semanal() {
        #expect(streak(["2026-10-11", "2026-10-04"], frequencia: "Semanal") == 2)
    }

    @Test func mensal() {
        #expect(streak(["2026-09-01", "2026-08-01", "2026-06-01"], frequencia: "Mensal") == 2)
    }

    @Test func pausaNoMeioNaoQuebra() {
        let pausados = EstatisticasViewModel.periodosPausados([("2026-10-17", "2026-10-18")], frequencia: "Diária")
        #expect(streak(["2026-10-14", "2026-10-15", "2026-10-16", "2026-10-19"], pausados: pausados) == 4)
    }

    @Test func periodoCompletoDuranteAPausaConta() {
        let pausados = EstatisticasViewModel.periodosPausados([("2026-10-18", hoje)], frequencia: "Diária")
        #expect(streak(["2026-10-16", "2026-10-17", "2026-10-19"], pausados: pausados) == 3)
    }

    @Test func pausaSemanalNeutralizaAsSemanasTocadas() {
        let pausados = EstatisticasViewModel.periodosPausados([("2026-10-07", "2026-10-13")], frequencia: "Semanal")
        #expect(pausados == ["2026-10-04", "2026-10-11"])
        #expect(streak(["2026-09-27", "2026-09-20"], pausados: pausados, frequencia: "Semanal") == 2)
    }
}

@MainActor
struct MapaCalorTests {
    let hoje = "2026-10-20"

    @Test func diariaComecaNumDomingoETerminaHoje() {
        let periodos = EstatisticasViewModel.periodosUltimoAno(frequencia: "Diária", hoje: hoje)
        #expect(periodos.first == "2025-10-19")
        #expect(periodos.last == hoje)
        #expect(periodos.count == 367)
        #expect(periodos == periodos.sorted())
    }

    @Test func semanal52Semanas() {
        let periodos = EstatisticasViewModel.periodosUltimoAno(frequencia: "Semanal", hoje: hoje)
        #expect(periodos.count == 52)
        #expect(periodos.last == "2026-10-18")
        #expect(periodos.first == "2025-10-26")
    }

    @Test func mensal12Meses() {
        let periodos = EstatisticasViewModel.periodosUltimoAno(frequencia: "Mensal", hoje: hoje)
        #expect(periodos.count == 12)
        #expect(periodos.first == "2025-11-01")
        #expect(periodos.last == "2026-10-01")
    }
}
