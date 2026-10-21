import Testing
@testable import KaizenApp

// 2026-10-20 é uma terça-feira; o domingo dessa semana é 2026-10-18
@MainActor
struct DataUtilTests {

    @Test func diaAnteriorCruzaMesEAno() {
        #expect(DataUtil.diaAnterior(a: "2026-11-01") == "2026-10-31")
        #expect(DataUtil.diaAnterior(a: "2026-03-01") == "2026-02-28")
        #expect(DataUtil.diaAnterior(a: "2026-01-01") == "2025-12-31")
    }

    @Test(arguments: [
        ("2026-10-18", "2026-10-18"),   // domingo
        ("2026-10-20", "2026-10-18"),   // terça
        ("2026-10-24", "2026-10-18"),   // sábado
        ("2026-11-03", "2026-11-01"),   // semana que começa no dia 1
        ("2027-01-01", "2026-12-27"),   // semana que cruza o ano
    ])
    func inicioDaSemanaEhDomingo(dia: String, domingo: String) {
        #expect(DataUtil.inicioPeriodo(dia, frequencia: "Semanal") == domingo)
    }

    @Test func inicioDoMesEhDia1() {
        #expect(DataUtil.inicioPeriodo("2026-10-20", frequencia: "Mensal") == "2026-10-01")
        #expect(DataUtil.inicioPeriodo("2026-10-01", frequencia: "Mensal") == "2026-10-01")
        #expect(DataUtil.inicioPeriodo("2026-02-28", frequencia: "Mensal") == "2026-02-01")
    }

    @Test func diariaEhOProprioDia() {
        #expect(DataUtil.inicioPeriodo("2026-10-20", frequencia: "Diária") == "2026-10-20")
    }

    @Test func periodoAnterior() {
        #expect(DataUtil.periodoAnterior(a: "2026-10-20", frequencia: "Diária") == "2026-10-19")
        #expect(DataUtil.periodoAnterior(a: "2026-10-18", frequencia: "Semanal") == "2026-10-11")
        #expect(DataUtil.periodoAnterior(a: "2026-03-01", frequencia: "Mensal") == "2026-02-01")
        #expect(DataUtil.periodoAnterior(a: "2026-01-01", frequencia: "Mensal") == "2025-12-01")
    }

    @Test func conclusaoValeSoNoPeriodoAtual() {
        let hoje = "2026-10-20"
        // Diária: só hoje
        #expect(DataUtil.concluidaNoPeriodoAtual("2026-10-20", frequencia: "Diária", hoje: hoje))
        #expect(!DataUtil.concluidaNoPeriodoAtual("2026-10-19", frequencia: "Diária", hoje: hoje))
        // Semanal: de domingo 18 em diante
        #expect(DataUtil.concluidaNoPeriodoAtual("2026-10-18", frequencia: "Semanal", hoje: hoje))
        #expect(!DataUtil.concluidaNoPeriodoAtual("2026-10-17", frequencia: "Semanal", hoje: hoje))
        // Mensal: de 1º de outubro em diante
        #expect(DataUtil.concluidaNoPeriodoAtual("2026-10-01", frequencia: "Mensal", hoje: hoje))
        #expect(!DataUtil.concluidaNoPeriodoAtual("2026-09-30", frequencia: "Mensal", hoje: hoje))
        // Vazio = nunca concluída
        #expect(!DataUtil.concluidaNoPeriodoAtual("", frequencia: "Diária", hoje: hoje))
    }
}
