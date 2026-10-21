import Foundation
import Combine

class TarefaViewModel: ObservableObject {
    @Published var tarefas: [Tarefa] = []
    private let dao = TarefaDAO()
    private let historicoDao = HistoricoDAO()
    private let rotinaId: Int64

    init(rotinaId: Int64) {
        self.rotinaId = rotinaId
    }

    func carregar() {
        tarefas = dao.listarPorRotina(rotinaId)
        registrarProgressoAtual()
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

    // Sempre que a lista de tarefas muda, atualiza o histórico de hoje
    private func registrarProgressoAtual() {
        let total = tarefas.count
        let concluidas = tarefas.filter { $0.concluidaHoje }.count
        historicoDao.registrarProgressoHoje(rotinaId: rotinaId, total: total, concluidas: concluidas)
    }
}
