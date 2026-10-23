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

    // Registra (ou atualiza) o progresso do período atual de uma rotina.
    // A coluna "data" guarda o início do período: o dia, o domingo da semana ou o dia 1 do mês
    func registrarProgresso(rotinaId rid: Int64, frequencia: String, total: Int, concluidas: Int) {
        let periodo = DataUtil.periodoAtual(frequencia: frequencia)
        let existente = table.filter(rotinaId == rid && data == periodo)

        if let _ = try? db?.pluck(existente) {
            try? db?.run(existente.update(
                totalTarefas <- total,
                tarefasConcluidas <- concluidas
            ))
        } else {
            try? db?.run(table.insert(
                rotinaId <- rid,
                data <- periodo,
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
