import Foundation

// Uma tarefa dentro de uma rotina. Pode ser de marcar, de anotar um valor ou de contar vezes
struct Tarefa: Identifiable {
    var id: Int64?
    var rotinaId: Int64
    var nome: String
    var ordem: Int
    var concluidaHoje: Bool
    var nota: String = ""   // observação opcional, ex.: "30 min", "3 séries de 12"
    var diasSemana: Set<Int> = []   // em rotinas diárias: dias em que a tarefa aparece (vazio = todos)
    var horario: String = ""        // lembrete da tarefa, "HH:mm" (vazio = sem lembrete)

    // Tipo "check" (marcar), "valor" (anotar um número, ex.: água 3 L) ou "vezes" (contar quantas vezes
    // fez no período, ex.: academia 3 vezes na semana — cada toque soma 1). "vezes" é um valor com unidade fixa.
    var tipo: String = "check"
    var unidade: String = ""        // valor: "L", "páginas", "min"…
    var meta: Double? = nil         // valor: alvo do período (nil = qualquer valor conta como feito)
    var valorAtual: Double = 0      // valor: o anotado no período atual
    var saude: String = ""          // valor: métrica do app Saúde que preenche a tarefa (vazio = à mão)

    var ehValor: Bool { tipo == "valor" || tipo == "vezes" }
    var ehContagem: Bool { tipo == "vezes" }

    func aparece(em dia: String) -> Bool {
        DiasSemana.inclui(diasSemana, dia: dia)
    }

    // Tarefa de valor fica feita ao bater a meta (ou, sem meta, com qualquer valor anotado)
    func atingiu(_ valor: Double) -> Bool {
        meta.map { valor >= $0 } ?? (valor > 0)
    }

    // "1,5 / 3 L", "2 páginas", "— / 3 L"; contagem: "1 de 3 vezes"
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

    // Progresso 0…1 pro círculo (sem meta: 0 ou 1)
    var progressoValor: Double {
        guard let meta, meta > 0 else { return valorAtual > 0 ? 1 : 0 }
        return min(valorAtual / meta, 1)
    }
}
