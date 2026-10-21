import Foundation
import SQLite

class HistoricoDAO {
    let db = DatabaseManager.shared.db
    let table = Table("historico_rotina")

    let id = Expression<Int64>("id")
    let rotinaId = Expression<Int64>("rotinaId")
    let data = Expression<String>("data")
    let totalTarefas = Expression<Int>("totalTarefas")
    let tarefasConcluidas = Expression<Int>("tarefasConcluidas")

    private func hojeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // Registra (ou atualiza) o progresso de hoje para uma rotina
    func registrarProgressoHoje(rotinaId rid: Int64, total: Int, concluidas: Int) {
        let hoje = hojeString()
        let existente = table.filter(rotinaId == rid && data == hoje)

        if let _ = try? db?.pluck(existente) {
            try? db?.run(existente.update(
                totalTarefas <- total,
                tarefasConcluidas <- concluidas
            ))
        } else {
            try? db?.run(table.insert(
                rotinaId <- rid,
                data <- hoje,
                totalTarefas <- total,
                tarefasConcluidas <- concluidas
            ))
        }
    }

    // Retorna o histórico de uma rotina, do mais recente para o mais antigo
    func listarPorRotina(_ rid: Int64) -> [HistoricoDia] {
        var lista: [HistoricoDia] = []
        let query = table.filter(rotinaId == rid).order(data.desc)
        if let rows = try? db?.prepare(query) {
            for row in rows {
                lista.append(HistoricoDia(
                    id: row[id],
                    rotinaId: row[rotinaId],
                    data: row[data],
                    totalTarefas: row[totalTarefas],
                    tarefasConcluidas: row[tarefasConcluidas]
                ))
            }
        }
        return lista
    }
}
