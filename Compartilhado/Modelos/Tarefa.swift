import Foundation

struct Tarefa: Identifiable {
    var id: Int64?
    var rotinaId: Int64
    var nome: String
    var ordem: Int
    var concluidaHoje: Bool
    var nota: String = ""
    var diasSemana: Set<Int> = []
    var horario: String = ""

    var tipo: String = "check"
    var unidade: String = ""
    var meta: Double? = nil
    var valorAtual: Double = 0
    var saude: String = ""

    var ehValor: Bool { tipo == "valor" || tipo == "vezes" }
    var ehContagem: Bool { tipo == "vezes" }

    func aparece(em dia: String) -> Bool {
        DiasSemana.inclui(diasSemana, dia: dia)
    }

    func atingiu(_ valor: Double) -> Bool {
        meta.map { valor >= $0 } ?? (valor > 0)
    }

    var valorDescrito: String {
        if ehContagem {
            let feitas = Int(valorAtual)
            guard let meta else { return feitas == 1 ? "1 vez" : "\(feitas) vezes" }
            return "\(feitas) de \(Int(meta)) \(Int(meta) == 1 ? "vez" : "vezes")"
        }
        let atual = valorAtual > 0 ? NumeroUtil.formatar(valorAtual) : "—"
        let sufixo = unidade.isEmpty ? "" : " \(unidade)"
        if let meta { return "\(atual) / \(NumeroUtil.formatar(meta))\(sufixo)" }
        return "\(atual)\(sufixo)"
    }

    var progressoValor: Double {
        guard let meta, meta > 0 else { return valorAtual > 0 ? 1 : 0 }
        return min(valorAtual / meta, 1)
    }
}
