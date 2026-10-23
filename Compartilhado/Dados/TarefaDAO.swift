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
    let nota = Expression<String>("nota")
    let diasSemana = Expression<String>("diasSemana")

    func inserir(_ tarefa: Tarefa) {
        let insert = table.insert(
            rotinaId <- tarefa.rotinaId,
            nome <- tarefa.nome,
            ordem <- tarefa.ordem,
            concluidaHoje <- tarefa.concluidaHoje,
            dataConclusao <- (tarefa.concluidaHoje ? DataUtil.hoje() : ""),
            nota <- tarefa.nota,
            diasSemana <- DiasSemana.codificar(tarefa.diasSemana)
        )
        try? db?.run(insert)
    }

    // Por padrão só as tarefas do dia (em rotinas diárias, uma tarefa pode valer só em alguns dias);
    // `dia: nil` traz todas, pra edição e organização
    func listarPorRotina(_ idRotina: Int64, frequencia: String, dia: String? = DataUtil.hoje()) -> [Tarefa] {
        var lista: [Tarefa] = []
        let query = table.filter(rotinaId == idRotina).order(ordem)
        if let rows = try? db?.prepare(query) {
            for row in rows {
                // Só conta como concluída se foi marcada no período atual (dia, semana ou mês) —
                // assim a lista "reseta" quando começa um período novo
                let concluida = DataUtil.concluidaNoPeriodoAtual(row[dataConclusao], frequencia: frequencia)
                lista.append(Tarefa(
                    id: row[id],
                    rotinaId: row[rotinaId],
                    nome: row[nome],
                    ordem: row[ordem],
                    concluidaHoje: concluida,
                    nota: row[nota],
                    diasSemana: DiasSemana.decodificar(row[diasSemana])
                ))
            }
        }
        if let dia, frequencia == "Diária" {
            return lista.filter { $0.aparece(em: dia) }
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

    // Troca nome, nota e dias — não mexe na conclusão da tarefa
    func editar(_ tarefa: Tarefa, nome novoNome: String, nota novaNota: String, dias: Set<Int>) {
        guard let tarefaId = tarefa.id else { return }
        try? db?.run(table.filter(id == tarefaId).update(
            nome <- novoNome, nota <- novaNota, diasSemana <- DiasSemana.codificar(dias)
        ))
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
