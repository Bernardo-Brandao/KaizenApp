import Foundation
import Testing
@testable import KaizenApp

@MainActor
struct ReordenarTests {
    @Test(arguments: [
        (0, 3, [1, 2, 0, 3, 4]),
        (4, 0, [4, 0, 1, 2, 3]),
        (1, 5, [0, 2, 3, 4, 1]),
        (2, 2, [0, 1, 2, 3, 4]),
        (2, 3, [0, 1, 2, 3, 4]),
    ])
    func moverUmItem(origem: Int, destino: Int, esperado: [Int]) {
        let resultado = TarefaViewModel.reordenar([0, 1, 2, 3, 4], de: IndexSet(integer: origem), para: destino)
        #expect(resultado == esperado)
    }

    @Test func moverVariosItens() {
        let resultado = TarefaViewModel.reordenar([0, 1, 2, 3, 4, 5], de: IndexSet([1, 3]), para: 5)
        #expect(resultado == [0, 2, 4, 1, 3, 5])
    }
}

@MainActor
struct ProgressoTests {
    @Test func historicoDia() {
        let metade = HistoricoDia(id: 1, rotinaId: 1, data: "2026-10-20", totalTarefas: 4, tarefasConcluidas: 2)
        #expect(metade.percentual == 0.5)
        #expect(!metade.completoNoDia)

        let completo = HistoricoDia(id: 2, rotinaId: 1, data: "2026-10-20", totalTarefas: 3, tarefasConcluidas: 3)
        #expect(completo.completoNoDia)

        let vazio = HistoricoDia(id: 3, rotinaId: 1, data: "2026-10-20", totalTarefas: 0, tarefasConcluidas: 0)
        #expect(vazio.percentual == 0)
        #expect(!vazio.completoNoDia)
    }

    @Test func progressoRotina() {
        #expect(ProgressoRotina(concluidas: 3, total: 5).percentual == 0.6)
        #expect(ProgressoRotina(concluidas: 5, total: 5).completo)
        #expect(!ProgressoRotina(concluidas: 0, total: 0).completo)
    }
}

@MainActor
struct ModeloRotinaTests {
    @Test func modelosSaoValidos() {
        let modelos = ModeloRotina.todos
        #expect(!modelos.isEmpty)
        #expect(Set(modelos.map(\.nome)).count == modelos.count)
        for modelo in modelos {
            #expect(["Diária", "Semanal", "Mensal"].contains(modelo.frequencia), "\(modelo.nome)")
            #expect(!modelo.tarefas.isEmpty, "\(modelo.nome)")
            #expect(Rotina.normalizarIcone(modelo.icone) == modelo.icone, "\(modelo.nome)")
            #expect(Set(modelo.tarefas.map(\.nome)).count == modelo.tarefas.count, "\(modelo.nome)")
        }
    }
}
