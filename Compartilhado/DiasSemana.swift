import Foundation

// Dias da semana em que uma rotina diária (ou uma tarefa) vale.
// Números do Calendar: 1 = domingo … 7 = sábado. Conjunto vazio = todos os dias.
enum DiasSemana {
    static let todos: Set<Int> = Set(1...7)
    static let nomesCurtos = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    static let iniciais = ["D", "S", "T", "Q", "Q", "S", "S"]

    // Banco guarda como texto ("2,4,6"); vazio = todos
    static func decodificar(_ texto: String) -> Set<Int> {
        Set(texto.split(separator: ",").compactMap { Int($0) }.filter { (1...7).contains($0) })
    }

    static func codificar(_ dias: Set<Int>) -> String {
        normalizar(dias).sorted().map(String.init).joined(separator: ",")
    }

    // Todos os 7 marcados vira vazio (= todos), pra não ter duas formas de dizer "todo dia"
    static func normalizar(_ dias: Set<Int>) -> Set<Int> {
        dias == todos ? [] : dias.intersection(todos)
    }

    static func inclui(_ dias: Set<Int>, dia: String) -> Bool {
        guard !dias.isEmpty else { return true }
        return DataUtil.diaDaSemana(dia).map(dias.contains) ?? true
    }

    // "Todo dia", "Dias úteis", "Fins de semana", "Sex" ou "Seg, Qua, Sex"
    static func descricao(_ dias: Set<Int>) -> String {
        let dias = normalizar(dias)
        if dias.isEmpty { return "Todo dia" }
        if dias == [2, 3, 4, 5, 6] { return "Dias úteis" }
        if dias == [1, 7] { return "Fins de semana" }
        return dias.sorted().map { nomesCurtos[$0 - 1] }.joined(separator: ", ")
    }
}
