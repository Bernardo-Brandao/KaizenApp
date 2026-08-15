import Foundation
import SQLite

class RotinaDAO {
    let db = DatabaseManager.shared.db
    let table = Table("rotinas")

    let id = Expression<Int64>("id")
    let nome = Expression<String>("nome")
    let descricao = Expression<String>("descricao")
    let frequencia = Expression<String>("frequencia")
    let ativa = Expression<Bool>("ativa")

    // CREATE
    func inserir(_ rotina: Rotina) {
        let insert = table.insert(
            nome <- rotina.nome,
            descricao <- rotina.descricao,
            frequencia <- rotina.frequencia,
            ativa <- rotina.ativa
        )
        try? db?.run(insert)
    }

    // READ
    func listarTodas() -> [Rotina] {
        var lista: [Rotina] = []
        if let rows = try? db?.prepare(table) {
            for row in rows {
                lista.append(Rotina(
                    id: row[id],
                    nome: row[nome],
                    descricao: row[descricao],
                    frequencia: row[frequencia],
                    ativa: row[ativa]
                ))
            }
        }
        return lista
    }

    // UPDATE
    func atualizar(_ rotina: Rotina) {
        guard let rotinaId = rotina.id else { return }
        let registro = table.filter(id == rotinaId)
        try? db?.run(registro.update(
            nome <- rotina.nome,
            descricao <- rotina.descricao,
            frequencia <- rotina.frequencia,
            ativa <- rotina.ativa
        ))
    }

    // DELETE
    func excluir(_ rotina: Rotina) {
        guard let rotinaId = rotina.id else { return }
        let registro = table.filter(id == rotinaId)
        try? db?.run(registro.delete())
    }
}
