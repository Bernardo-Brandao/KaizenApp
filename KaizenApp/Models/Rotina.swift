import Foundation

struct Rotina: Identifiable {
    var id: Int64?
    var nome: String
    var descricao: String
    var frequencia: String   // determina o nivel da frequencia
    var ativa: Bool
}
