import Foundation
import Testing
@testable import KaizenApp

// Rotinas e tarefas em dias específicos ("hoje" = terça 2026-10-20; sexta = 2026-10-16 e 2026-10-23)
@MainActor
struct DiasSemanaTests {
    @Test func codificarENormalizar() {
        #expect(DiasSemana.codificar([6, 2]) == "2,6")
        #expect(DiasSemana.decodificar("2,6") == [2, 6])
        #expect(DiasSemana.codificar(DiasSemana.todos) == "")      // todos = vazio
        #expect(DiasSemana.decodificar("") == [])
        #expect(DiasSemana.decodificar("0,9,x,3") == [3])            // ignora lixo
    }

    @Test func descricao() {
        #expect(DiasSemana.descricao([]) == "Todo dia")
        #expect(DiasSemana.descricao([6]) == "Sex")
        #expect(DiasSemana.descricao([2, 4, 6]) == "Seg, Qua, Sex")
        #expect(DiasSemana.descricao([2, 3, 4, 5, 6]) == "Dias úteis")
        #expect(DiasSemana.descricao([1, 7]) == "Fins de semana")
    }

    @Test func rotinaSoDeSexta() {
        let rotina = Rotina(id: 1, nome: "Sexta", descricao: "", frequencia: "Diária", ativa: true,
                            horarioLembrete: "", lembreteAtivo: false, diasSemana: [6])
        #expect(rotina.programada(em: "2026-10-16"))     // sexta
        #expect(!rotina.programada(em: "2026-10-20"))    // terça
        #expect(rotina.frequenciaDescrita == "Diária · Sex")

        // Semanal ignora os dias
        var semanal = rotina
        semanal.frequencia = "Semanal"
        #expect(semanal.programada(em: "2026-10-20"))
    }

    @Test func tarefaDeDiasEspecificos() {
        let tarefa = Tarefa(id: 1, rotinaId: 1, nome: "Perna", ordem: 0, concluidaHoje: false, diasSemana: [6])
        #expect(tarefa.aparece(em: "2026-10-16"))
        #expect(!tarefa.aparece(em: "2026-10-20"))
        let sempre = Tarefa(id: 2, rotinaId: 1, nome: "Água", ordem: 1, concluidaHoje: false)
        #expect(sempre.aparece(em: "2026-10-20"))
    }

    @Test func folgaNaoQuebraASequencia() {
        // Rotina de seg, qua e sex; completa nas sextas 09 e 16 e na segunda 12, quarta 14
        let completos: Set = ["2026-10-09", "2026-10-12", "2026-10-14", "2026-10-16"]
        let streak = EstatisticasViewModel.calcularStreak(completos: completos, pausados: [], frequencia: "Diária",
                                                          hoje: "2026-10-17", diasSemana: [2, 4, 6])
        #expect(streak == 4)
        // Sem os dias, os buracos (sáb, dom, ter, qui) quebram
        let semDias = EstatisticasViewModel.calcularStreak(completos: completos, pausados: [], frequencia: "Diária",
                                                           hoje: "2026-10-17")
        #expect(semDias == 1)
        #expect(EstatisticasViewModel.calcularRecorde(completos: completos, pausados: [], frequencia: "Diária",
                                                      diasSemana: [2, 4, 6]) == 4)
    }

    @Test func lembreteSoNosDiasDaRotina() {
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = TimeZone(identifier: "UTC")!
        let inicio = calendario.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 8))!   // terça
        let datas = NotificationManager.proximasDatas(frequencia: "Diária", diaLembrete: 1, hora: 9, minuto: 0,
                                                      aPartirDe: inicio, quantidade: 3, diasSemana: [6],
                                                      calendario: calendario)
        let dias = datas.map { calendario.component(.day, from: $0) }
        #expect(dias == [23, 30, 6])   // as próximas três sextas
    }

    @Test func resumoSemanalContaSoDiasProgramados() {
        // Rotina só de sexta, completa na sexta 16
        let sexta = DadosRotinaSemana(nome: "Sexta", icone: "🏋️", frequencia: "Diária",
                                      historico: [HistoricoDia(id: 1, rotinaId: 1, data: "2026-10-16",
                                                               totalTarefas: 5, tarefasConcluidas: 5)],
                                      diasSemana: [6])
        let resumo = ResumoSemanal.calcular(rotinas: [sexta], inicioSemana: "2026-10-11")
        #expect(resumo.taxa == 1)
        #expect(resumo.diasPerfeitos == 1)
        #expect(resumo.linhas[0].dias == [nil, nil, nil, nil, nil, true, nil])
    }
}
