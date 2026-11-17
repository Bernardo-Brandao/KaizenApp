import Foundation

struct Rotina: Identifiable, Hashable {
    var id: Int64?
    var nome: String
    var descricao: String
    var frequencia: String
    var ativa: Bool
    var horarioLembrete: String
    var lembreteAtivo: Bool
    var categoriaId: Int64? = nil
    var diaLembrete: Int = 1
    var icone: String = ""
    var diasSemana: Set<Int> = []

    static let iconePadrao = "📋"

    func programada(em dia: String) -> Bool {
        frequencia != "Diária" || DiasSemana.inclui(diasSemana, dia: dia)
    }

    var frequenciaDescrita: String {
        frequencia == "Diária" && !diasSemana.isEmpty ? "Diária · \(DiasSemana.descricao(diasSemana))" : frequencia
    }

    var iconeExibido: String { icone.isEmpty ? Self.iconePadrao : icone }

    static func normalizarIcone(_ texto: String) -> String {
        texto.trimmingCharacters(in: .whitespacesAndNewlines).first.map(String.init) ?? ""
    }
}
