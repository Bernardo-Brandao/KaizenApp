import Foundation
import Combine

class TarefaViewModel: ObservableObject {
    @Published var tarefas: [Tarefa] = []
    @Published var todasTarefas: [Tarefa] = []
    private let dao = TarefaDAO()
    private let historicoDao = HistoricoDAO()
    private let rotinaId: Int64
    var frequencia: String
    var programadaHoje = true

    var tarefasDeOutrosDias: [Tarefa] {
        let deHoje = Set(tarefas.compactMap(\.id))
        return todasTarefas.filter { !deHoje.contains($0.id ?? -1) }
    }

    init(rotinaId: Int64, frequencia: String) {
        self.rotinaId = rotinaId
        self.frequencia = frequencia
    }

    func carregar() {
        tarefas = dao.listarPorRotina(rotinaId, frequencia: frequencia)
        todasTarefas = dao.listarPorRotina(rotinaId, frequencia: frequencia, dia: nil)
        registrarProgressoAtual()
    }

    func adicionar(nome: String, nota: String = "", dias: Set<Int> = [], horario: String = "",
                   tipo: String = "check", unidade: String = "", meta: Double? = nil, saude: String = "") {
        let novaOrdem = todasTarefas.count
        let nova = Tarefa(id: nil, rotinaId: rotinaId, nome: nome, ordem: novaOrdem, concluidaHoje: false,
                          nota: nota.trimmingCharacters(in: .whitespacesAndNewlines),
                          diasSemana: DiasSemana.normalizar(dias), horario: horario,
                          tipo: tipo, unidade: unidade.trimmingCharacters(in: .whitespaces),
                          meta: tipo == "check" ? nil : meta, saude: tipo == "valor" ? saude : "")
        dao.inserir(nova)
        carregar()
        atualizarLembrete()
    }

    @discardableResult
    func alternarConcluida(_ tarefa: Tarefa) -> Bool {
        let estavaCompleta = rotinaCompleta
        var atualizada = tarefa
        atualizada.concluidaHoje.toggle()
        dao.atualizar(atualizada, frequencia: frequencia)
        carregar()
        atualizarLembrete()
        return !estavaCompleta && rotinaCompleta
    }

    @discardableResult
    func registrarValor(_ tarefa: Tarefa, valor: Double) -> Bool {
        let estavaCompleta = rotinaCompleta
        dao.registrarValor(tarefa, valor: valor, frequencia: frequencia)
        carregar()
        atualizarLembrete()
        return !estavaCompleta && rotinaCompleta
    }

    var rotinaCompleta: Bool {
        !tarefas.isEmpty && tarefas.allSatisfy { $0.concluidaHoje }
    }

    func editar(_ tarefa: Tarefa, nome: String, nota: String, dias: Set<Int>, horario: String,
                tipo: String, unidade: String, meta: Double?, saude: String = "") {
        let nomeLimpo = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nomeLimpo.isEmpty else { return }
        dao.editar(tarefa, nome: nomeLimpo, nota: nota.trimmingCharacters(in: .whitespacesAndNewlines),
                   dias: DiasSemana.normalizar(dias), horario: horario,
                   tipo: tipo, unidade: unidade.trimmingCharacters(in: .whitespaces),
                   meta: tipo == "check" ? nil : meta, saude: saude)
        carregar()
        atualizarLembrete()
    }

    func mover(de origem: IndexSet, para destino: Int) {
        dao.salvarOrdem(Self.reordenar(todasTarefas, de: origem, para: destino))
        carregar()
    }

    static func reordenar<T>(_ itens: [T], de origem: IndexSet, para destino: Int) -> [T] {
        let movidos = origem.map { itens[$0] }
        var reordenados = itens
        for indice in origem.sorted(by: >) {
            reordenados.remove(at: indice)
        }
        let insercao = destino - origem.filter { $0 < destino }.count
        reordenados.insert(contentsOf: movidos, at: insercao)
        return reordenados
    }

    func excluir(_ tarefa: Tarefa) {
        dao.excluir(tarefa)
        carregar()
        atualizarLembrete()
    }

    private func atualizarLembrete() {
        NotificationManager.shared.atualizarLembrete(rotinaId: rotinaId)
        WidgetSync.atualizar()
    }

    private func registrarProgressoAtual() {
        guard programadaHoje else { return }
        let total = tarefas.count
        let concluidas = tarefas.filter { $0.concluidaHoje }.count
        historicoDao.registrarProgresso(rotinaId: rotinaId, frequencia: frequencia, total: total, concluidas: concluidas)
    }
}
