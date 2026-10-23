import Foundation
import Combine

// Quantas tarefas da rotina foram concluídas no período atual (dia, semana ou mês)
struct ProgressoRotina {
    let concluidas: Int
    let total: Int

    var percentual: Double {
        total == 0 ? 0 : Double(concluidas) / Double(total)
    }

    var completo: Bool {
        total > 0 && concluidas == total
    }
}

class RotinaViewModel: ObservableObject {
    @Published var rotinas: [Rotina] = []
    @Published var progresso: [Int64: ProgressoRotina] = [:]   // por id da rotina
    private let dao = RotinaDAO()
    private let tarefaDao = TarefaDAO()

    func carregar() {
        rotinas = dao.listarTodas()

        var novoProgresso: [Int64: ProgressoRotina] = [:]
        for rotina in rotinas {
            guard let id = rotina.id else { continue }
            let tarefas = tarefaDao.listarPorRotina(id, frequencia: rotina.frequencia)
            novoProgresso[id] = ProgressoRotina(
                concluidas: tarefas.filter { $0.concluidaHoje }.count,
                total: tarefas.count
            )
        }
        progresso = novoProgresso
        WidgetSync.atualizar()
    }

    func adicionar(nome: String, descricao: String, frequencia: String, horarioLembrete: String, lembreteAtivo: Bool, diaLembrete: Int, categoriaId: Int64?, icone: String = "") {
        let nova = Rotina(
            id: nil,
            nome: nome,
            descricao: descricao,
            frequencia: frequencia,
            ativa: true,
            horarioLembrete: horarioLembrete,
            lembreteAtivo: lembreteAtivo,
            categoriaId: categoriaId,
            diaLembrete: diaLembrete,
            icone: icone
        )

        if let novoId = dao.inserir(nova) {
            var comId = nova
            comId.id = novoId
            NotificationManager.shared.agendarLembrete(para: comId)
        }
        carregar()
    }

    func atualizar(_ rotina: Rotina) {
        dao.atualizar(rotina)
        if rotina.lembreteAtivo {
            NotificationManager.shared.agendarLembrete(para: rotina)
        } else {
            NotificationManager.shared.cancelarLembrete(para: rotina)
        }
        carregar()
    }

    // Pausa ou retoma a rotina: guarda o intervalo da pausa e liga/desliga o lembrete
    func alternarPausa(_ rotina: Rotina) {
        guard let id = rotina.id else { return }
        var atualizada = rotina
        atualizada.ativa.toggle()
        dao.atualizar(atualizada)

        if atualizada.ativa {
            PausaDAO().retomar(rotinaId: id)
            NotificationManager.shared.agendarLembrete(para: atualizada)
        } else {
            PausaDAO().pausar(rotinaId: id)
            NotificationManager.shared.cancelarLembrete(para: atualizada)
        }
        carregar()
    }

    func excluir(_ rotina: Rotina) {
        dao.excluir(rotina)
        NotificationManager.shared.cancelarLembrete(para: rotina)
        carregar()
    }
}
