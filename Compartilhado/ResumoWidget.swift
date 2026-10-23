import Foundation

// O que o widget mostra de cada rotina. Montado direto do banco (que fica no App Group),
// então o widget sempre vê o mesmo que o app.
struct ResumoRotina: Identifiable {
    let id: Int64
    let nome: String
    let tarefas: [ResumoTarefa]
    let corHex: String?      // cor da categoria, se tiver
    let validoAte: Date      // início do próximo período — dali em diante o progresso zera

    var total: Int { tarefas.count }

    // Progresso considerando que o período pode virar entre uma atualização do widget e outra
    func concluidas(em agora: Date) -> Int {
        agora >= validoAte ? 0 : tarefas.filter(\.concluida).count
    }

    func completa(em agora: Date) -> Bool {
        total > 0 && concluidas(em: agora) == total
    }
}

struct ResumoTarefa: Identifiable {
    let id: Int64
    let nome: String
    let concluida: Bool
}

enum ResumoWidget {
    // Rotinas ativas, na mesma ordem da lista do app
    static func carregar() -> [ResumoRotina] {
        let categorias = CategoriaDAO().listarTodas()
        let tarefaDao = TarefaDAO()

        return RotinaDAO().listarTodas().compactMap { rotina in
            guard rotina.ativa, let id = rotina.id,
                  let validoAte = DataUtil.inicioProximoPeriodo(frequencia: rotina.frequencia)
            else { return nil }
            let tarefas = tarefaDao.listarPorRotina(id, frequencia: rotina.frequencia).compactMap { tarefa in
                tarefa.id.map { ResumoTarefa(id: $0, nome: tarefa.nome, concluida: tarefa.concluidaHoje) }
            }
            return ResumoRotina(
                id: id,
                nome: rotina.nome,
                tarefas: tarefas,
                corHex: categorias.first { $0.id == rotina.categoriaId }?.corHex,
                validoAte: validoAte
            )
        }
    }
}
