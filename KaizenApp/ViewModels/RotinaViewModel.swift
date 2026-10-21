import Foundation
import Combine

class RotinaViewModel: ObservableObject {
    @Published var rotinas: [Rotina] = []
    private let dao = RotinaDAO()

    func carregar() {
        rotinas = dao.listarTodas()
    }

    func adicionar(nome: String, descricao: String, frequencia: String, horarioLembrete: String, lembreteAtivo: Bool, diaLembrete: Int, categoriaId: Int64?) {
        let nova = Rotina(
            id: nil,
            nome: nome,
            descricao: descricao,
            frequencia: frequencia,
            ativa: true,
            horarioLembrete: horarioLembrete,
            lembreteAtivo: lembreteAtivo,
            categoriaId: categoriaId,
            diaLembrete: diaLembrete
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

    func excluir(_ rotina: Rotina) {
        dao.excluir(rotina)
        NotificationManager.shared.cancelarLembrete(para: rotina)
        carregar()
    }
}
