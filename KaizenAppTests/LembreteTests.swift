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
}
