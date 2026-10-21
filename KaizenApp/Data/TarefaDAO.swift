import Foundation
import SQLite

class TarefaDAO {
    let db = DatabaseManager.shared.db
    let table = Table("tarefas")

    let id = Expression<Int64>("id")
    let rotinaId = Expression<Int64>("rotinaId")
    let nome = Expression<String>("nome")
    let ordem = Expression<Int>("ordem")
    let concluidaHoje = Expression<Bool>("concluidaHoje")
    let dataConclusao = Expression<String>("dataConclusao")

    func inserir(_ tarefa: Tarefa) {
        let insert = table.insert(
            rotinaId <- tarefa.rotinaId,
            nome <- tarefa.nome,
            ordem <- tarefa.ordem,
            concluidaHoje <- tarefa.concluidaHoje,
            dataConclusao <- (tarefa.concluidaHoje ? DataUtil.hoje() : "")
        )
        try? db?.run(insert)
    }

    func listarPorRotina(_ idRotina: Int64, frequencia: String) -> [Tarefa] {
        var lista: [Tarefa] = []
        let query = table.filter(rotinaId == idRotina).order(ordem)
        let periodoAtual = DataUtil.periodoAtual(frequencia: frequencia)
        if let rows = try? db?.prepare(query) {
            for row in rows {
                // Só conta como concluída se foi marcada no período atual (dia, semana ou mês) —
                // assim a lista "reseta" quando começa um período novo
                let conclusao = row[dataConclusao]
                let concluida = !conclusao.isEmpty
                    && DataUtil.inicioPeriodo(conclusao, frequencia: frequencia) == periodoAtual
                lista.append(Tarefa(
                    id: row[id],
                    rotinaId: row[rotinaId],
                    nome: row[nome],
                    ordem: row[ordem],
                    concluidaHoje: concluida
                ))
            }
        }
        return lista
    }

    func atualizar(_ tarefa: Tarefa) {
        guard let tarefaId = tarefa.id else { return }
        let registro = table.filter(id == tarefaId)
        try? db?.run(registro.update(
            nome <- tarefa.nome,
            concluidaHoje <- tarefa.concluidaHoje,
            dataConclusao <- (tarefa.concluidaHoje ? DataUtil.hoje() : "")
        ))
    }

    // Só troca o nome — não mexe na conclusão da tarefa
    func renomear(_ tarefa: Tarefa, para novoNome: String) {
        guard let tarefaId = tarefa.id else { return }
        try? db?.run(table.filter(id == tarefaId).update(nome <- novoNome))
    }

    // Grava a ordem das tarefas conforme a posição de cada uma na lista
    func salvarOrdem(_ tarefas: [Tarefa]) {
        try? db?.transaction {
            for (posicao, tarefa) in tarefas.enumerated() {
                guard let tarefaId = tarefa.id else { continue }
                try db?.run(table.filter(id == tarefaId).update(ordem <- posicao))
            }
        }
    }

    func excluir(_ tarefa: Tarefa) {
        guard let tarefaId = tarefa.id else { return }
        let registro = table.filter(id == tarefaId)
        try? db?.run(registro.delete())
    }
}
