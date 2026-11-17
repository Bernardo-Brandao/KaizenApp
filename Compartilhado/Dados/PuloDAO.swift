import Foundation
import SQLite

class PuloDAO {
    let db = DatabaseManager.shared.db
    let table = Table("pulos")

    let rotinaId = Expression<Int64>("rotinaId")
    let periodo = Expression<String>("periodo")

    func pular(rotinaId rid: Int64, periodo p: String) {
        try? db?.run(table.insert(or: .ignore, rotinaId <- rid, periodo <- p))
    }

    func desfazer(rotinaId rid: Int64, periodo p: String) {
        try? db?.run(table.filter(rotinaId == rid && periodo == p).delete())
    }

    func periodos(rotinaId rid: Int64) -> Set<String> {
        guard let rows = try? db?.prepare(table.filter(rotinaId == rid)) else { return [] }
        return Set(rows.map { $0[periodo] })
    }

    func puladaAgora(_ rotina: Rotina) -> Bool {
        guard let rid = rotina.id else { return false }
        let atual = DataUtil.periodoAtual(frequencia: rotina.frequencia)
        return (try? db?.pluck(table.filter(rotinaId == rid && periodo == atual))) != nil
    }
}
