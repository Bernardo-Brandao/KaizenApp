import Foundation

// Marca/desmarca uma tarefa fora da tela da rotina (usado pelo widget interativo).
// Faz o mesmo que o TarefaViewModel: grava a conclusão, atualiza o histórico do período e o lembrete.
enum ConclusaoTarefa {
    static func alternar(tarefaId: Int64, rotinaId: Int64) {
        guard let rotina = RotinaDAO().buscar(id: rotinaId) else { return }
        let dao = TarefaDAO()
        guard var tarefa = dao.listarPorRotina(rotinaId, frequencia: rotina.frequencia)
            .first(where: { $0.id == tarefaId }) else { return }

        tarefa.concluidaHoje.toggle()
        dao.atualizar(tarefa)

        let tarefas = dao.listarPorRotina(rotinaId, frequencia: rotina.frequencia)
        HistoricoDAO().registrarProgresso(
            rotinaId: rotinaId,
            frequencia: rotina.frequencia,
            total: tarefas.count,
            concluidas: tarefas.filter(\.concluidaHoje).count
        )
        // Completar a rotina cancela o lembrete do período (lembrete inteligente)
        NotificationManager.shared.atualizarLembrete(rotinaId: rotinaId)
    }
}
