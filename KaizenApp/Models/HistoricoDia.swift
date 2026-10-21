import Foundation

struct HistoricoDia: Identifiable {
    var id: Int64?
    var rotinaId: Int64
    var data: String            // formato "yyyy-MM-dd"
    var totalTarefas: Int
    var tarefasConcluidas: Int

    var percentual: Double {
        totalTarefas == 0 ? 0 : Double(tarefasConcluidas) / Double(totalTarefas)
    }

    var completoNoDia: Bool {
        totalTarefas > 0 && tarefasConcluidas == totalTarefas
    }
}
