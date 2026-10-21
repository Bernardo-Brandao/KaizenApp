import Foundation
import WidgetKit

// Grava o resumo das rotinas ativas no App Group e pede pro widget se redesenhar
enum WidgetSync {
    static func atualizar() {
        let categorias = CategoriaDAO().listarTodas()
        let tarefaDao = TarefaDAO()

        let resumos: [ResumoRotina] = RotinaDAO().listarTodas().compactMap { rotina in
            guard rotina.ativa, let id = rotina.id,
                  let validoAte = DataUtil.inicioProximoPeriodo(frequencia: rotina.frequencia)
            else { return nil }
            let tarefas = tarefaDao.listarPorRotina(id, frequencia: rotina.frequencia)
            return ResumoRotina(
                id: id,
                nome: rotina.nome,
                concluidas: tarefas.filter { $0.concluidaHoje }.count,
                total: tarefas.count,
                corHex: categorias.first { $0.id == rotina.categoriaId }?.corHex,
                validoAte: validoAte
            )
        }

        ResumoWidget.salvar(resumos)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
