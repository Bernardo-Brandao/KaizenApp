import Foundation
import Testing
@testable import KaizenApp

@MainActor
struct ReordenarTests {
    // `destino` segue o .onMove da List: posição antes de remover o item
    @Test(arguments: [
        (0, 3, [1, 2, 0, 3, 4]),   // desce o primeiro
        (4, 0, [4, 0, 1, 2, 3]),   // sobe o último pro topo
        (1, 5, [0, 2, 3, 4, 1]),   // manda pro fim
        (2, 2, [0, 1, 2, 3, 4]),   // solta no mesmo lugar
        (2, 3, [0, 1, 2, 3, 4]),   // logo abaixo de si mesmo = mesmo lugar
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

        // Sem tarefas não conta como completo
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
