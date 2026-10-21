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
    let horarioLembrete = Expression<String>("horarioLembrete")
    let lembreteAtivo = Expression<Bool>("lembreteAtivo")
    let categoriaId = Expression<Int64?>("categoriaId")

    // CREATE — agora retorna o id gerado, pra podermos agendar a notificação certa
    @discardableResult
    func inserir(_ rotina: Rotina) -> Int64? {
        let insert = table.insert(
            nome <- rotina.nome,
            descricao <- rotina.descricao,
            frequencia <- rotina.frequencia,
            ativa <- rotina.ativa,
            horarioLembrete <- rotina.horarioLembrete,
            lembreteAtivo <- rotina.lembreteAtivo,
            categoriaId <- rotina.categoriaId
        )
        return try? db?.run(insert)
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
                    ativa: row[ativa],
                    horarioLembrete: row[horarioLembrete],
                    lembreteAtivo: row[lembreteAtivo],
                    categoriaId: row[categoriaId]
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
            ativa <- rotina.ativa,
            horarioLembrete <- rotina.horarioLembrete,
            lembreteAtivo <- rotina.lembreteAtivo,
            categoriaId <- rotina.categoriaId
        ))
    }

    // DELETE
    func excluir(_ rotina: Rotina) {
        guard let rotinaId = rotina.id else { return }
        let registro = table.filter(id == rotinaId)
        try? db?.run(registro.delete())
    }
}
