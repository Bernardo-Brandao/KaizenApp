import Foundation

struct Rotina: Identifiable, Hashable {
    var id: Int64?
    var nome: String
    var descricao: String
    var frequencia: String   // "Diária", "Semanal", "Mensal"
    var ativa: Bool
    var horarioLembrete: String   // formato "HH:mm", vazio se não tiver lembrete
    var lembreteAtivo: Bool
    var categoriaId: Int64? = nil   // nil = sem categoria
    var diaLembrete: Int = 1        // Semanal: dia da semana (1 = domingo … 7 = sábado); Mensal: dia do mês (1–28)
}
