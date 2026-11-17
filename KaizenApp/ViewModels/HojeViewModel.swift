import Foundation
import Combine

struct ItemHoje: Identifiable {
    let tarefa: Tarefa
    let rotina: Rotina
    let corHex: String?
    var id: Int64 { tarefa.id ?? 0 }
}

class HojeViewModel: ObservableObject {
    @Published var doDia: [ItemHoje] = []
    @Published var daSemana: [ItemHoje] = []
    @Published var doMes: [ItemHoje] = []
    @Published var puladas: [Rotina] = []

    func carregar() {
        let hoje = DataUtil.hoje()
        let categorias = CategoriaDAO().listarTodas()
        let tarefaDao = TarefaDAO()
        let puloDao = PuloDAO()
        var dia: [ItemHoje] = [], semana: [ItemHoje] = [], mes: [ItemHoje] = [], puladas: [Rotina] = []

        for rotina in RotinaDAO().listarTodas() where rotina.ativa && rotina.programada(em: hoje) {
            guard let id = rotina.id else { continue }
            if puloDao.puladaAgora(rotina) {
                puladas.append(rotina)
                continue
            }
            let corHex = categorias.first { $0.id == rotina.categoriaId }?.corHex
            let itens = tarefaDao.listarPorRotina(id, frequencia: rotina.frequencia)
                .map { ItemHoje(tarefa: $0, rotina: rotina, corHex: corHex) }
            switch rotina.frequencia {
            case "Semanal": semana += itens
            case "Mensal": mes += itens
            default: dia += itens
            }
        }

        doDia = Self.ordenar(dia)
        daSemana = semana
        doMes = mes
        self.puladas = puladas
    }

    func alternarPulo(_ rotina: Rotina) {
        guard let id = rotina.id else { return }
        let periodo = DataUtil.periodoAtual(frequencia: rotina.frequencia)
        if puladas.contains(where: { $0.id == id }) {
            PuloDAO().desfazer(rotinaId: id, periodo: periodo)
        } else {
            PuloDAO().pular(rotinaId: id, periodo: periodo)
        }
        NotificationManager.shared.atualizarLembrete(rotinaId: id)
        WidgetSync.atualizar()
        carregar()
    }

    static func ordenar(_ itens: [ItemHoje]) -> [ItemHoje] {
        itens.enumerated().sorted { a, b in
            let ha = a.element.tarefa.horario, hb = b.element.tarefa.horario
            if ha.isEmpty != hb.isEmpty { return hb.isEmpty }
            if ha != hb { return ha < hb }
            return a.offset < b.offset
        }
        .map(\.element)
    }

    var feitasHoje: Int { doDia.filter(\.tarefa.concluidaHoje).count }

    @discardableResult
    func alternar(_ item: ItemHoje) -> Bool {
        let estavaCompleta = rotinaCompleta(item.rotina.id)
        ConclusaoTarefa.alternar(tarefaId: item.id, rotinaId: item.rotina.id ?? 0)
        return depoisDeMudar(item, estavaCompleta: estavaCompleta)
    }

    @discardableResult
    func registrarValor(_ item: ItemHoje, valor: Double) -> Bool {
        let estavaCompleta = rotinaCompleta(item.rotina.id)
        ConclusaoTarefa.registrarValor(item.tarefa, valor: valor, rotinaId: item.rotina.id ?? 0)
        return depoisDeMudar(item, estavaCompleta: estavaCompleta)
    }

    private func depoisDeMudar(_ item: ItemHoje, estavaCompleta: Bool) -> Bool {
        WidgetSync.atualizar()
        carregar()
        return !estavaCompleta && rotinaCompleta(item.rotina.id)
    }

    private func rotinaCompleta(_ rotinaId: Int64?) -> Bool {
        let tarefas = (doDia + daSemana + doMes).filter { $0.rotina.id == rotinaId }
        return !tarefas.isEmpty && tarefas.allSatisfy(\.tarefa.concluidaHoje)
    }
}
