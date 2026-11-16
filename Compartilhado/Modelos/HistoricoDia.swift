import Foundation

// Um registro do histórico: em um período, quantas tarefas a rotina tinha e quantas foram feitas
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
