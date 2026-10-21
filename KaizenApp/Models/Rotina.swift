import Foundation

struct Rotina: Identifiable {
    var id: Int64?
    var nome: String
    var descricao: String
    var frequencia: String   // "Diária", "Semanal", "Mensal"
    var ativa: Bool
    var horarioLembrete: String   // formato "HH:mm", vazio se não tiver lembrete
    var lembreteAtivo: Bool
}
