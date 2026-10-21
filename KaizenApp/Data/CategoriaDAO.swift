import Foundation
import SQLite

class CategoriaDAO {
    let db = DatabaseManager.shared.db
    let table = Table("categorias")

    let id = Expression<Int64>("id")
    let nome = Expression<String>("nome")
    let corHex = Expression<String>("corHex")

    func inserir(_ categoria: Categoria) {
        let insert = table.insert(
            nome <- categoria.nome,
            corHex <- categoria.corHex
        )
        try? db?.run(insert)
    }

    func listarTodas() -> [Categoria] {
        var lista: [Categoria] = []
        if let rows = try? db?.prepare(table) {
            for row in rows {
                lista.append(Categoria(id: row[id], nome: row[nome], corHex: row[corHex]))
            }
        }
        return lista
    }

    func excluir(_ categoria: Categoria) {
        guard let categoriaId = categoria.id else { return }
        let registro = table.filter(id == categoriaId)
        try? db?.run(registro.delete())

        // Rotinas dessa categoria ficam "sem categoria" em vez de apontar pra um id que não existe
        let rotinas = Table("rotinas")
        let rotinaCategoriaId = Expression<Int64?>("categoriaId")
        try? db?.run(rotinas.filter(rotinaCategoriaId == categoriaId).update(rotinaCategoriaId <- nil))
    }
}
