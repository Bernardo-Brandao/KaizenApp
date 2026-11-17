import Foundation

struct ResumoRotina: Identifiable {
    let id: Int64
    let nome: String
    let tarefas: [ResumoTarefa]
    let corHex: String?
    let validoAte: Date
    var frequencia: String = "Diária"
    var icone: String = ""
    var programadaHoje = true

    var total: Int { tarefas.count }

    func concluidas(em agora: Date) -> Int {
        agora < validoAte ? tarefas.filter(\.concluida).count : 0
    }

    func completa(em agora: Date) -> Bool {
        total > 0 && concluidas(em: agora) == total
    }
}

struct ResumoTarefa: Identifiable {
    let id: Int64
    let nome: String
    let concluida: Bool
    var nota: String = ""
    var horario: String = ""
    var valorTexto: String? = nil
}

enum ResumoWidget {
    static func carregar() -> [ResumoRotina] {
        let categorias = CategoriaDAO().listarTodas()
        let tarefaDao = TarefaDAO()
        let puloDao = PuloDAO()

        return RotinaDAO().listarTodas().compactMap { rotina in
            guard rotina.ativa, let id = rotina.id,
                  let validoAte = DataUtil.inicioProximoPeriodo(frequencia: rotina.frequencia)
            else { return nil }
            let tarefas = tarefaDao.listarPorRotina(id, frequencia: rotina.frequencia).compactMap { tarefa in
                tarefa.id.map { ResumoTarefa(id: $0, nome: tarefa.nome, concluida: tarefa.concluidaHoje, nota: tarefa.nota,
                                        horario: tarefa.horario,
                                        valorTexto: tarefa.ehValor ? tarefa.valorDescrito : nil) }
            }
            return ResumoRotina(
                id: id,
                nome: rotina.nome,
                tarefas: tarefas,
                corHex: categorias.first { $0.id == rotina.categoriaId }?.corHex,
                validoAte: validoAte,
                frequencia: rotina.frequencia,
                icone: rotina.iconeExibido,
                programadaHoje: rotina.programada(em: DataUtil.hoje()) && !puloDao.puladaAgora(rotina)
            )
        }
    }
}
