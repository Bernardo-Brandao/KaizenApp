import Foundation
import Combine

class TarefaViewModel: ObservableObject {
    @Published var tarefas: [Tarefa] = []
    private let dao = TarefaDAO()
    private let rotinaId: Int64

    init(rotinaId: Int64) {
        self.rotinaId = rotinaId
    }

    func carregar() {
        tarefas = dao.listarPorRotina(rotinaId)
    }

    func adicionar(nome: String) {
        let novaOrdem = tarefas.count
        let nova = Tarefa(id: nil, rotinaId: rotinaId, nome: nome, ordem: novaOrdem, concluidaHoje: false)
        dao.inserir(nova)
        carregar()
    }

    func alternarConcluida(_ tarefa: Tarefa) {
        var atualizada = tarefa
        atualizada.concluidaHoje.toggle()
        dao.atualizar(atualizada)
        carregar()
    }

    func excluir(_ tarefa: Tarefa) {
        dao.excluir(tarefa)
        carregar()
    }
}
