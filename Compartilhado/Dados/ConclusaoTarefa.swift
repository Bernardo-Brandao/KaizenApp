import Foundation

// Marca/desmarca uma tarefa fora da tela da rotina (usado pelo widget interativo).
// Faz o mesmo que o TarefaViewModel: grava a conclusão, atualiza o histórico do período e o lembrete.
enum ConclusaoTarefa {
    static func alternar(tarefaId: Int64, rotinaId: Int64) {
        guard let rotina = RotinaDAO().buscar(id: rotinaId) else { return }
        let dao = TarefaDAO()
        guard var tarefa = dao.listarPorRotina(rotinaId, frequencia: rotina.frequencia)
            .first(where: { $0.id == tarefaId }), !tarefa.ehValor else { return }

        tarefa.concluidaHoje.toggle()
        dao.atualizar(tarefa, frequencia: rotina.frequencia)

        registrarHistorico(rotina)
        // Completar a rotina cancela o lembrete do período (lembrete inteligente)
        NotificationManager.shared.atualizarLembrete(rotinaId: rotinaId)
    }

    // "Marcar tudo como feito" (botão da notificação): conclui as tarefas que faltam no período
    static func concluirTodas(rotinaId: Int64) {
        guard let rotina = RotinaDAO().buscar(id: rotinaId) else { return }
        let dao = TarefaDAO()
        for tarefa in dao.listarPorRotina(rotinaId, frequencia: rotina.frequencia) where !tarefa.concluidaHoje {
            concluir(tarefa, dao: dao, frequencia: rotina.frequencia)
        }

        registrarHistorico(rotina)
        NotificationManager.shared.atualizarLembrete(rotinaId: rotinaId)
    }

    // "Marcar como feito" na notificação de um horário: conclui só as tarefas daquele lembrete
    static func concluir(tarefaIds: [Int64], rotinaId: Int64) {
        guard let rotina = RotinaDAO().buscar(id: rotinaId) else { return }
        let dao = TarefaDAO()
        for tarefa in dao.listarPorRotina(rotinaId, frequencia: rotina.frequencia, dia: nil)
        where tarefaIds.contains(tarefa.id ?? -1) && !tarefa.concluidaHoje {
            concluir(tarefa, dao: dao, frequencia: rotina.frequencia)
        }
        registrarHistorico(rotina)
        NotificationManager.shared.atualizarLembrete(rotinaId: rotinaId)
    }

    // Anota o valor de uma tarefa de valor fora da tela da rotina (tela Hoje)
    static func registrarValor(_ tarefa: Tarefa, valor: Double, rotinaId: Int64) {
        guard let rotina = RotinaDAO().buscar(id: rotinaId) else { return }
        TarefaDAO().registrarValor(tarefa, valor: valor, frequencia: rotina.frequencia)
        registrarHistorico(rotina)
        NotificationManager.shared.atualizarLembrete(rotinaId: rotinaId)
    }

    // Marcar: conclui. Valor: preenche a meta (sem meta não há o que preencher — fica como está)
    private static func concluir(_ tarefa: Tarefa, dao: TarefaDAO, frequencia: String) {
        if tarefa.ehValor {
            if let meta = tarefa.meta {
                dao.registrarValor(tarefa, valor: max(meta, tarefa.valorAtual), frequencia: frequencia)
            }
        } else {
            var feita = tarefa
            feita.concluidaHoje = true
            dao.atualizar(feita, frequencia: frequencia)
        }
    }

    // MARK: - Períodos que já passaram ("Dias anteriores")

    // Marca/desmarca uma tarefa num período passado e refaz o total daquele período no histórico
    static func alternar(_ tarefa: Tarefa, noPeriodo periodo: String, rotina: Rotina) {
        guard let tarefaId = tarefa.id else { return }
        TarefaDAO().definirConclusao(tarefaId: tarefaId, periodo: periodo, feita: !tarefa.concluidaHoje)
        registrarHistorico(rotina, periodo: periodo)
    }

    static func registrarValor(_ tarefa: Tarefa, valor: Double, noPeriodo periodo: String, rotina: Rotina) {
        TarefaDAO().registrarValor(tarefa, valor: valor, frequencia: rotina.frequencia, periodo: periodo)
        registrarHistorico(rotina, periodo: periodo)
    }

    // Total de um período passado a partir das conclusões por tarefa
    static func registrarHistorico(_ rotina: Rotina, periodo: String) {
        guard let id = rotina.id else { return }
        let tarefas = TarefaDAO().listarNoPeriodo(id, frequencia: rotina.frequencia, periodo: periodo)
        HistoricoDAO().definir(rotinaId: id, periodo: periodo, total: tarefas.count,
                               concluidas: tarefas.filter(\.concluidaHoje).count)
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
