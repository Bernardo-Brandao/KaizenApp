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
    var icone: String = ""          // emoji da rotina (vazio = ícone padrão)

    static let iconePadrao = "📋"

    // Emoji pra mostrar: o escolhido ou o padrão
    var iconeExibido: String { icone.isEmpty ? Self.iconePadrao : icone }

    // Guarda só o primeiro emoji/caractere digitado
    static func normalizarIcone(_ texto: String) -> String {
        texto.trimmingCharacters(in: .whitespacesAndNewlines).first.map(String.init) ?? ""
    }
}
