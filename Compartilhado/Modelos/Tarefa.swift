import Foundation

struct Tarefa: Identifiable {
    var id: Int64?
    var rotinaId: Int64
    var nome: String
    var ordem: Int
    var concluidaHoje: Bool
    var nota: String = ""   // observação opcional, ex.: "30 min", "3 séries de 12"
    var diasSemana: Set<Int> = []   // em rotinas diárias: dias em que a tarefa aparece (vazio = todos)

    func aparece(em dia: String) -> Bool {
        DiasSemana.inclui(diasSemana, dia: dia)
    }
}
