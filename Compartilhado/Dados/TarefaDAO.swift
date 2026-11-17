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
    let horario = Expression<String>("horario")
    let tipo = Expression<String>("tipo")
    let unidade = Expression<String>("unidade")
    let meta = Expression<Double?>("meta")
    let saude = Expression<String>("saude")

    let registros = Table("registros_tarefa")
    let registroTarefaId = Expression<Int64>("tarefaId")
    let registroData = Expression<String>("data")
    let registroValor = Expression<Double>("valor")

    let conclusoes = Table("conclusoes")
    let conclusaoTarefaId = Expression<Int64>("tarefaId")
    let conclusaoPeriodo = Expression<String>("periodo")

    func inserir(_ tarefa: Tarefa) {
        let insert = table.insert(
            rotinaId <- tarefa.rotinaId,
            nome <- tarefa.nome,
            ordem <- tarefa.ordem,
            concluidaHoje <- tarefa.concluidaHoje,
            dataConclusao <- (tarefa.concluidaHoje ? DataUtil.hoje() : ""),
            nota <- tarefa.nota,
            diasSemana <- DiasSemana.codificar(tarefa.diasSemana),
            horario <- tarefa.horario,
            tipo <- tarefa.tipo,
            unidade <- tarefa.unidade,
            meta <- tarefa.meta,
            saude <- tarefa.saude
        )
        try? db?.run(insert)
    }

    func listarPorRotina(_ idRotina: Int64, frequencia: String, dia: String? = DataUtil.hoje()) -> [Tarefa] {
        var lista: [Tarefa] = []
        let query = table.filter(rotinaId == idRotina).order(ordem)
        let periodo = DataUtil.periodoAtual(frequencia: frequencia)
        if let rows = try? db?.prepare(query) {
            for row in rows {
                let concluida = DataUtil.concluidaNoPeriodoAtual(row[dataConclusao], frequencia: frequencia)
                lista.append(Tarefa(
                    id: row[id],
                    rotinaId: row[rotinaId],
                    nome: row[nome],
                    ordem: row[ordem],
                    concluidaHoje: concluida,
                    nota: row[nota],
                    diasSemana: DiasSemana.decodificar(row[diasSemana]),
                    horario: row[horario],
                    tipo: row[tipo],
                    unidade: row[unidade],
                    meta: row[meta],
                    valorAtual: row[tipo] != "check" ? valor(tarefaId: row[id], periodo: periodo) : 0,
                    saude: row[saude]
                ))
            }
        }
        if let dia, frequencia == "Diária" {
            return lista.filter { $0.aparece(em: dia) }
        }
        return lista
    }

    func atualizar(_ tarefa: Tarefa, frequencia: String) {
        guard let tarefaId = tarefa.id else { return }
        let registro = table.filter(id == tarefaId)
        try? db?.run(registro.update(
            nome <- tarefa.nome,
            concluidaHoje <- tarefa.concluidaHoje,
            dataConclusao <- (tarefa.concluidaHoje ? DataUtil.hoje() : "")
        ))
        definirConclusao(tarefaId: tarefaId, periodo: DataUtil.periodoAtual(frequencia: frequencia), feita: tarefa.concluidaHoje)
    }

    func definirConclusao(tarefaId tid: Int64, periodo p: String, feita: Bool) {
        if feita {
            try? db?.run(conclusoes.insert(or: .ignore, conclusaoTarefaId <- tid, conclusaoPeriodo <- p))
        } else {
            try? db?.run(conclusoes.filter(conclusaoTarefaId == tid && conclusaoPeriodo == p).delete())
        }
    }

    func listarNoPeriodo(_ idRotina: Int64, frequencia: String, periodo: String) -> [Tarefa] {
        let feitas = Set((try? db?.prepare(conclusoes.filter(conclusaoPeriodo == periodo)))?
            .map { $0[conclusaoTarefaId] } ?? [])
        return listarPorRotina(idRotina, frequencia: frequencia, dia: frequencia == "Diária" ? periodo : nil).map { tarefa in
            var noPeriodo = tarefa
            noPeriodo.concluidaHoje = feitas.contains(tarefa.id ?? -1)
            noPeriodo.valorAtual = tarefa.ehValor ? valor(tarefaId: tarefa.id ?? -1, periodo: periodo) : 0
            return noPeriodo
        }
    }

    func editar(_ tarefa: Tarefa, nome novoNome: String, nota novaNota: String, dias: Set<Int>, horario novoHorario: String,
                tipo novoTipo: String, unidade novaUnidade: String, meta novaMeta: Double?, saude novaSaude: String = "") {
        guard let tarefaId = tarefa.id else { return }
        try? db?.run(table.filter(id == tarefaId).update(
            nome <- novoNome, nota <- novaNota, diasSemana <- DiasSemana.codificar(dias), horario <- novoHorario,
            tipo <- novoTipo, unidade <- novaUnidade, meta <- novaMeta,
            saude <- (novoTipo == "valor" ? novaSaude : "")
        ))
    }

    func valor(tarefaId tid: Int64, periodo: String) -> Double {
        guard let linha = try? db?.pluck(registros.filter(registroTarefaId == tid && registroData == periodo)) else {
            return 0
        }
        return linha[registroValor]
    }

    func registrarValor(_ tarefa: Tarefa, valor novoValor: Double, frequencia: String, periodo: String? = nil) {
        guard let tarefaId = tarefa.id else { return }
        let atual = DataUtil.periodoAtual(frequencia: frequencia)
        let periodo = periodo ?? atual
        let valor = max(0, novoValor)
        try? db?.run(registros.insert(or: .replace,
                                      registroTarefaId <- tarefaId, registroData <- periodo, registroValor <- valor))
        if periodo == atual {
            var atualizada = tarefa
            atualizada.concluidaHoje = tarefa.atingiu(valor)
            atualizar(atualizada, frequencia: frequencia)
        } else {
            definirConclusao(tarefaId: tarefaId, periodo: periodo, feita: tarefa.atingiu(valor))
        }
    }

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
        try? db?.run(registros.filter(registroTarefaId == tarefaId).delete())
        try? db?.run(conclusoes.filter(conclusaoTarefaId == tarefaId).delete())
    }
}
