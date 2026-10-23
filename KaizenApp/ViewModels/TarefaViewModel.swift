import Foundation
import Combine

class TarefaViewModel: ObservableObject {
    @Published var tarefas: [Tarefa] = []          // as de hoje (em rotinas diárias, algumas valem só em certos dias)
    @Published var todasTarefas: [Tarefa] = []     // todas, pra organizar e pra seção "Em outros dias"
    private let dao = TarefaDAO()
    private let historicoDao = HistoricoDAO()
    private let rotinaId: Int64
    var frequencia: String   // define o período do reset: dia, semana ou mês
    var programadaHoje = true // rotina diária com dias escolhidos: false nos dias de folga

    // Tarefas que não aparecem hoje (só em outros dias da semana)
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

    func adicionar(nome: String, nota: String = "", dias: Set<Int> = []) {
        let novaOrdem = todasTarefas.count
        let nova = Tarefa(id: nil, rotinaId: rotinaId, nome: nome, ordem: novaOrdem, concluidaHoje: false,
                          nota: nota.trimmingCharacters(in: .whitespacesAndNewlines),
                          diasSemana: DiasSemana.normalizar(dias))
        dao.inserir(nova)
        carregar()
        atualizarLembrete()
    }

    // Retorna true quando esse toque completou a rotina no período (pra comemorar)
    @discardableResult
    func alternarConcluida(_ tarefa: Tarefa) -> Bool {
        let estavaCompleta = rotinaCompleta
        var atualizada = tarefa
        atualizada.concluidaHoje.toggle()
        dao.atualizar(atualizada)
        carregar()
        atualizarLembrete()
        return !estavaCompleta && rotinaCompleta
    }

    var rotinaCompleta: Bool {
        !tarefas.isEmpty && tarefas.allSatisfy { $0.concluidaHoje }
    }

    func editar(_ tarefa: Tarefa, nome: String, nota: String, dias: Set<Int>) {
        let nomeLimpo = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nomeLimpo.isEmpty else { return }
        dao.editar(tarefa, nome: nomeLimpo, nota: nota.trimmingCharacters(in: .whitespacesAndNewlines),
                   dias: DiasSemana.normalizar(dias))
        carregar()
        atualizarLembrete()   // mudar os dias pode mudar se a rotina está completa hoje
    }

    func mover(de origem: IndexSet, para destino: Int) {
        dao.salvarOrdem(Self.reordenar(todasTarefas, de: origem, para: destino))
        carregar()
    }

    // Mesmo comportamento do .onMove da List: `destino` é a posição antes da remoção
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

    // Completar (ou deixar de completar) a rotina muda se o lembrete do período ainda precisa tocar
    private func atualizarLembrete() {
        NotificationManager.shared.atualizarLembrete(rotinaId: rotinaId)
        WidgetSync.atualizar()
    }

    // Sempre que a lista de tarefas muda, atualiza o histórico do período atual
    // Em dia de folga da rotina não registra (o dia não conta pra sequência nem pra média)
    private func registrarProgressoAtual() {
        guard programadaHoje else { return }
        let total = tarefas.count
        let concluidas = tarefas.filter { $0.concluidaHoje }.count
        historicoDao.registrarProgresso(rotinaId: rotinaId, frequencia: frequencia, total: total, concluidas: concluidas)
    }
}
