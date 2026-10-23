import Foundation
import Testing
@testable import KaizenApp

// Texto que a Siri fala no "How are my routines?"
@MainActor
struct SiriTests {
    private func rotina(_ id: Int64, _ nome: String, feitas: Int, total: Int) -> ResumoRotina {
        let tarefas = (0..<total).map { ResumoTarefa(id: id * 10 + Int64($0), nome: "T\($0)", concluida: $0 < feitas) }
        return ResumoRotina(id: id, nome: nome, tarefas: tarefas, corHex: nil, validoAte: .distantFuture)
    }

    @Test func semRotinas() {
        #expect(ResumoRotinasIntent.resumo([], agora: .now) == "You don't have any routines with tasks yet.")
    }

    @Test func tudoFeito() {
        let uma = ResumoRotinasIntent.resumo([rotina(1, "Manhã", feitas: 2, total: 2)], agora: .now)
        #expect(uma == "All done! You completed your routine.")

        let duas = ResumoRotinasIntent.resumo([
            rotina(1, "Manhã", feitas: 2, total: 2),
            rotina(2, "Estudos", feitas: 1, total: 1),
        ], agora: .now)
        #expect(duas == "All done! You completed all 2 routines.")
    }

    @Test func umaPendente() {
        let texto = ResumoRotinasIntent.resumo([
            rotina(1, "Manhã", feitas: 2, total: 2),
            rotina(2, "Estudos", feitas: 1, total: 4),
        ], agora: .now)
        #expect(texto == "You completed 1 of 2 routines. Estudos is left, with 1 of 4 tasks done.")
    }

    @Test func variasPendentes() {
        let texto = ResumoRotinasIntent.resumo([
            rotina(1, "Estudos", feitas: 0, total: 3),
            rotina(2, "Academia", feitas: 1, total: 2),
        ], agora: .now)
        #expect(texto == "You completed 0 of 2 routines. 2 are left. Next up is Estudos, with 0 of 3 tasks done.")
    }
}
