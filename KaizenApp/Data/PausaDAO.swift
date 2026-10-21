import Foundation
import SQLite

// Intervalos em que uma rotina ficou pausada — usados pra não quebrar o streak
class PausaDAO {
    let db = DatabaseManager.shared.db
    let table = Table("pausas")

    let id = Expression<Int64>("id")
    let rotinaId = Expression<Int64>("rotinaId")
    let inicio = Expression<String>("inicio")   // "yyyy-MM-dd"
    let fim = Expression<String>("fim")         // "yyyy-MM-dd"; vazio enquanto a pausa está em andamento

    func pausar(rotinaId rid: Int64) {
        try? db?.run(table.insert(rotinaId <- rid, inicio <- DataUtil.hoje(), fim <- ""))
    }

    func retomar(rotinaId rid: Int64) {
        let emAndamento = table.filter(rotinaId == rid && fim == "")
        try? db?.run(emAndamento.update(fim <- DataUtil.hoje()))
    }

    // Pausas da rotina como (início, fim); a pausa em andamento termina hoje
    func listar(rotinaId rid: Int64) -> [(inicio: String, fim: String)] {
        var lista: [(inicio: String, fim: String)] = []
        if let rows = try? db?.prepare(table.filter(rotinaId == rid)) {
            for row in rows {
                let fimPausa = row[fim].isEmpty ? DataUtil.hoje() : row[fim]
                lista.append((inicio: row[inicio], fim: fimPausa))
            }
        }
        return lista
    }
}
