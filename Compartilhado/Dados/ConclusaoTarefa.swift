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

        registrarHistorico(rotina)
        // Completar a rotina cancela o lembrete do período (lembrete inteligente)
        NotificationManager.shared.atualizarLembrete(rotinaId: rotinaId)
    }

    // "Marcar tudo como feito" (botão da notificação): conclui as tarefas que faltam no período
    static func concluirTodas(rotinaId: Int64) {
        guard let rotina = RotinaDAO().buscar(id: rotinaId) else { return }
        let dao = TarefaDAO()
        for var tarefa in dao.listarPorRotina(rotinaId, frequencia: rotina.frequencia) where !tarefa.concluidaHoje {
            tarefa.concluidaHoje = true
            dao.atualizar(tarefa)
        }

        registrarHistorico(rotina)
        NotificationManager.shared.atualizarLembrete(rotinaId: rotinaId)
    }

    // Progresso do período no histórico (não registra em dia de folga da rotina)
    private static func registrarHistorico(_ rotina: Rotina) {
        guard let id = rotina.id, rotina.programada(em: DataUtil.hoje()) else { return }
        let tarefas = TarefaDAO().listarPorRotina(id, frequencia: rotina.frequencia)
        HistoricoDAO().registrarProgresso(
            rotinaId: id,
            frequencia: rotina.frequencia,
            total: tarefas.count,
            concluidas: tarefas.filter(\.concluidaHoje).count
        )
    }
}
