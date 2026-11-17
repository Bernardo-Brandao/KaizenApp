import Foundation

enum DiasSemana {
    static let todos: Set<Int> = Set(1...7)
    static let nomesCurtos = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    static let iniciais = ["D", "S", "T", "Q", "Q", "S", "S"]

    static func decodificar(_ texto: String) -> Set<Int> {
        Set(texto.split(separator: ",").compactMap { Int($0) }.filter { (1...7).contains($0) })
    }

    static func codificar(_ dias: Set<Int>) -> String {
        normalizar(dias).sorted().map(String.init).joined(separator: ",")
    }

    static func normalizar(_ dias: Set<Int>) -> Set<Int> {
        dias == todos ? [] : dias.intersection(todos)
    }

    static func inclui(_ dias: Set<Int>, dia: String) -> Bool {
        guard !dias.isEmpty else { return true }
        return DataUtil.diaDaSemana(dia).map(dias.contains) ?? true
    }

    static func descricao(_ dias: Set<Int>) -> String {
        let dias = normalizar(dias)
        if dias.isEmpty { return "Todo dia" }
        if dias == [2, 3, 4, 5, 6] { return "Dias úteis" }
        if dias == [1, 7] { return "Fins de semana" }
        return dias.sorted().map { nomesCurtos[$0 - 1] }.joined(separator: ", ")
    }
}
