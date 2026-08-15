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

    func inserir(_ tarefa: Tarefa) {
        let insert = table.insert(
            rotinaId <- tarefa.rotinaId,
            nome <- tarefa.nome,
            ordem <- tarefa.ordem,
            concluidaHoje <- tarefa.concluidaHoje
        )
        try? db?.run(insert)
    }

    func listarPorRotina(_ idRotina: Int64) -> [Tarefa] {
        var lista: [Tarefa] = []
        let query = table.filter(rotinaId == idRotina).order(ordem)
        if let rows = try? db?.prepare(query) {
            for row in rows {
                lista.append(Tarefa(
                    id: row[id],
                    rotinaId: row[rotinaId],
                    nome: row[nome],
                    ordem: row[ordem],
                    concluidaHoje: row[concluidaHoje]
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
            concluidaHoje <- tarefa.concluidaHoje
        ))
    }

    func excluir(_ tarefa: Tarefa) {
        guard let tarefaId = tarefa.id else { return }
        let registro = table.filter(id == tarefaId)
        try? db?.run(registro.delete())
    }
}
