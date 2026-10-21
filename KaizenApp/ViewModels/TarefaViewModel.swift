import Foundation
import Combine

class TarefaViewModel: ObservableObject {
    @Published var tarefas: [Tarefa] = []
    private let dao = TarefaDAO()
    private let historicoDao = HistoricoDAO()
    private let rotinaId: Int64
    var frequencia: String   // define o período do reset: dia, semana ou mês

    init(rotinaId: Int64, frequencia: String) {
        self.rotinaId = rotinaId
        self.frequencia = frequencia
    }

    func carregar() {
        tarefas = dao.listarPorRotina(rotinaId, frequencia: frequencia)
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

    func renomear(_ tarefa: Tarefa, para nome: String) {
        let nomeLimpo = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nomeLimpo.isEmpty else { return }
        dao.renomear(tarefa, para: nomeLimpo)
        carregar()
    }

    func mover(de origem: IndexSet, para destino: Int) {
        // Mesmo comportamento do .onMove da List: `destino` é a posição antes da remoção
        let movidas = origem.map { tarefas[$0] }
        var reordenadas = tarefas
        for indice in origem.sorted(by: >) {
            reordenadas.remove(at: indice)
        }
        let insercao = destino - origem.filter { $0 < destino }.count
        reordenadas.insert(contentsOf: movidas, at: insercao)

        dao.salvarOrdem(reordenadas)
        carregar()
    }

    func excluir(_ tarefa: Tarefa) {
        dao.excluir(tarefa)
        carregar()
    }

    // Sempre que a lista de tarefas muda, atualiza o histórico do período atual
    private func registrarProgressoAtual() {
        let total = tarefas.count
        let concluidas = tarefas.filter { $0.concluidaHoje }.count
        historicoDao.registrarProgresso(rotinaId: rotinaId, frequencia: frequencia, total: total, concluidas: concluidas)
    }
}
