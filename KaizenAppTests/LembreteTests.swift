import Foundation
import Testing
@testable import KaizenApp

// Datas de lembrete calculadas num calendário fixo (UTC, domingo primeiro) pra não depender do aparelho
@MainActor
struct LembreteTests {
    private var calendario: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = 1
        return c
    }

    private func data(_ texto: String, _ hora: Int = 0, _ minuto: Int = 0) -> Date {
        let partes = texto.split(separator: "-").map { Int($0)! }
        return calendario.date(from: DateComponents(year: partes[0], month: partes[1], day: partes[2], hour: hora, minute: minuto))!
    }

    private func dias(_ datas: [Date]) -> [String] {
        let f = DateFormatter()
        f.calendar = calendario
        f.timeZone = calendario.timeZone
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return datas.map { f.string(from: $0) }
    }

    @Test func diariaComecaHojeSeAindaNaoPassouDaHora() {
        // Terça 20/10 às 08:00, lembrete às 09:30
        let datas = NotificationManager.proximasDatas(frequencia: "Diária", diaLembrete: 1, hora: 9, minuto: 30,
                                                      aPartirDe: data("2026-10-20", 8), quantidade: 3, calendario: calendario)
        #expect(dias(datas) == ["2026-10-20 09:30", "2026-10-21 09:30", "2026-10-22 09:30"])
    }

    @Test func diariaPulaHojeSeJaPassouDaHora() {
        let datas = NotificationManager.proximasDatas(frequencia: "Diária", diaLembrete: 1, hora: 7, minuto: 0,
                                                      aPartirDe: data("2026-10-20", 8), quantidade: 2, calendario: calendario)
        #expect(dias(datas) == ["2026-10-21 07:00", "2026-10-22 07:00"])
    }

    @Test func semanalCaiNoDiaDaSemanaEscolhido() {
        // diaLembrete 6 = sexta
        let datas = NotificationManager.proximasDatas(frequencia: "Semanal", diaLembrete: 6, hora: 18, minuto: 0,
                                                      aPartirDe: data("2026-10-20", 8), quantidade: 3, calendario: calendario)
        #expect(dias(datas) == ["2026-10-23 18:00", "2026-10-30 18:00", "2026-11-06 18:00"])
    }

    @Test func mensalCaiNoDiaDoMesEscolhido() {
        let datas = NotificationManager.proximasDatas(frequencia: "Mensal", diaLembrete: 5, hora: 10, minuto: 0,
                                                      aPartirDe: data("2026-10-20", 8), quantidade: 3, calendario: calendario)
        #expect(dias(datas) == ["2026-11-05 10:00", "2026-12-05 10:00", "2027-01-05 10:00"])
    }

    // MARK: - Lembretes por tarefa (terça 20/10 às 08:00 UTC; "hoje" = 2026-10-20)

    private var rotinaDiaria: Rotina {
        Rotina(id: 1, nome: "Manhã", descricao: "", frequencia: "Diária", ativa: true,
               horarioLembrete: "", lembreteAtivo: false)
    }

    private func tarefa(_ id: Int64, _ nome: String, _ horario: String, feita: Bool = false,
                        dias: Set<Int> = []) -> Tarefa {
        Tarefa(id: id, rotinaId: 1, nome: nome, ordem: Int(id), concluidaHoje: feita,
               diasSemana: dias, horario: horario)
    }

    private func planejar(_ rotina: Rotina, _ tarefas: [Tarefa], dias: Int = 3) -> [NotificationManager.LembretePlanejado] {
        NotificationManager.planejarLembretes(rotina: rotina, tarefas: tarefas, aPartirDe: data("2026-10-20", 8),
                                              quantidadePorHorario: dias, hoje: "2026-10-20", calendario: calendario)
    }

    @Test func diaPuladoFicaSemLembrete() {
        // Ter 20/10 às 08:00, lembrete às 09:00 por 3 dias, com quarta 21/10 pulada
        let planejados = NotificationManager.planejarLembretes(
            rotina: rotinaDiaria, tarefas: [tarefa(1, "Correr", "09:00")], aPartirDe: data("2026-10-20", 8),
            quantidadePorHorario: 3, periodosPulados: ["2026-10-21"], hoje: "2026-10-20", calendario: calendario)
        #expect(dias(planejados.map(\.data)) == ["2026-10-20 09:00", "2026-10-22 09:00"])
    }

    @Test func tarefasDoMesmoHorarioViramUmLembreteSo() {
        let lembretes = planejar(rotinaDiaria, [
            tarefa(1, "Água", "09:00"), tarefa(2, "Alongar", "09:00"), tarefa(3, "Ler", "21:00"),
            tarefa(4, "Sem horário", ""),
        ], dias: 2)
        #expect(dias(lembretes.map(\.data)) == ["2026-10-20 09:00", "2026-10-20 21:00",
                                                 "2026-10-21 09:00", "2026-10-21 21:00"])
        #expect(lembretes[0].tarefas.map(\.nome) == ["Água", "Alongar"])
        #expect(lembretes[1].tarefas.map(\.nome) == ["Ler"])
    }

    @Test func tarefaFeitaHojeNaoEntraNoLembreteDeHoje() {
        let lembretes = planejar(rotinaDiaria, [
            tarefa(1, "Água", "09:00", feita: true), tarefa(2, "Alongar", "09:00"),
            tarefa(3, "Ler", "21:00", feita: true),
        ], dias: 2)
        // Hoje: 09:00 só com Alongar; 21:00 não toca. Amanhã: tudo de novo
        #expect(dias(lembretes.map(\.data)) == ["2026-10-20 09:00", "2026-10-21 09:00", "2026-10-21 21:00"])
        #expect(lembretes[0].tarefas.map(\.nome) == ["Alongar"])
        #expect(lembretes[1].tarefas.map(\.nome) == ["Água", "Alongar"])
    }

    @Test func tarefaSoDeSextaSoTocaNaSexta() {
        // Terça 20 → próximos dias 20, 21, 22, 23 (sexta)
        let lembretes = planejar(rotinaDiaria, [tarefa(1, "Perna", "18:00", dias: [6])], dias: 4)
        #expect(dias(lembretes.map(\.data)) == ["2026-10-23 18:00"])
    }

    @Test func rotinaSoDeSextaSoTemLembreteNaSexta() {
        var soSexta = rotinaDiaria
        soSexta.diasSemana = [6]
        let lembretes = planejar(soSexta, [tarefa(1, "Treino", "07:00")], dias: 2)
        #expect(dias(lembretes.map(\.data)) == ["2026-10-23 07:00", "2026-10-30 07:00"])
    }

    @Test func semanalUsaODiaDaRotinaEOHorarioDaTarefa() {
        var semanal = rotinaDiaria
        semanal.frequencia = "Semanal"
        semanal.diaLembrete = 7   // sábado
        let lembretes = planejar(semanal, [tarefa(1, "Faxina", "10:00"), tarefa(2, "Mercado", "16:30")], dias: 1)
        #expect(dias(lembretes.map(\.data)) == ["2026-10-24 10:00", "2026-10-24 16:30"])
    }
}

