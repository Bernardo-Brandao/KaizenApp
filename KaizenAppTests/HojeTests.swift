import Foundation
import Testing
@testable import KaizenApp

@MainActor
struct HojeTests {
    private func item(_ id: Int64, _ horario: String, rotina: Int64 = 1) -> ItemHoje {
        ItemHoje(tarefa: Tarefa(id: id, rotinaId: rotina, nome: "T\(id)", ordem: Int(id), concluidaHoje: false, horario: horario),
                 rotina: Rotina(id: rotina, nome: "R\(rotina)", descricao: "", frequencia: "Diária", ativa: true,
                                horarioLembrete: "", lembreteAtivo: false),
                 corHex: nil)
    }

    @Test func ordenaPorHorarioComAsSemHorarioNoFim() {
        let itens = [item(1, ""), item(2, "19:00"), item(3, "07:30", rotina: 2), item(4, ""), item(5, "07:30")]
        #expect(HojeViewModel.ordenar(itens).map(\.id) == [3, 5, 2, 1, 4])
    }

    @Test func parteDoDiaPeloHorario() {
        #expect(ParteDoDia(horario: "05:00") == .manha)
        #expect(ParteDoDia(horario: "11:59") == .manha)
        #expect(ParteDoDia(horario: "12:00") == .tarde)
        #expect(ParteDoDia(horario: "18:00") == .noite)
        #expect(ParteDoDia(horario: "") == .qualquerHora)
    }

    @Test func diasAnterioresComecamOntem() {
        let dias = DiasAnterioresView.periodosAnteriores(frequencia: "Diária", hoje: "2026-10-23")
        #expect(dias.count == 14)
        #expect(dias.first == "2026-10-22")
        #expect(dias.last == "2026-10-09")
    }

    @Test func semanasAnterioresComecamNoDomingoAnterior() {
        let semanas = DiasAnterioresView.periodosAnteriores(frequencia: "Semanal", hoje: "2026-10-23")
        #expect(semanas.count == 8)
        #expect(semanas.first == "2026-10-11")
    }

    @Test func tituloDoPeriodo() {
        #expect(DiasAnterioresView.titulo("2026-10-22", frequencia: "Diária", hoje: "2026-10-23") == "Ontem")
        #expect(DiasAnterioresView.titulo("2026-09-01", frequencia: "Mensal", hoje: "2026-10-23").hasPrefix("Setembro"))
    }

    @Test func diaPuladoNaoQuebraASequencia() {
        let streak = EstatisticasViewModel.calcularStreak(
            completos: ["2026-10-22", "2026-10-20"], pausados: ["2026-10-21"],
            frequencia: "Diária", hoje: "2026-10-23")
        #expect(streak == 2)
    }
}

@MainActor
struct FimDoDiaTests {
    @Test func semPendentesNaoNotifica() {
        #expect(NotificationManager.textoFimDoDia([]) == nil)
    }

    @Test func umaRotinaDizQualE() {
        let texto = NotificationManager.textoFimDoDia([("Treino", 1)])
        #expect(texto?.titulo == "Falta 1 tarefa hoje")
        #expect(texto?.corpo == "Na rotina Treino. Ainda dá tempo.")
    }

    @Test func variasRotinasSomamETemDetalhe() {
        let texto = NotificationManager.textoFimDoDia([("Foco", 1), ("Treino", 2)])
        #expect(texto?.titulo == "Faltam 3 tarefas hoje")
        #expect(texto?.corpo == "Foco: 1 · Treino: 2")
    }
}
