import Foundation
import Combine

class RotinaViewModel: ObservableObject {
    @Published var rotinas: [Rotina] = []
    private let dao = RotinaDAO()

    func carregar() {
        rotinas = dao.listarTodas()
    }

    func adicionar(nome: String, descricao: String, frequencia: String) {
        let nova = Rotina(id: nil, nome: nome, descricao: descricao, frequencia: frequencia, ativa: true)
        dao.inserir(nova)
        carregar()
    }

    func atualizar(_ rotina: Rotina) {
        dao.atualizar(rotina)
        carregar()
    }

    func excluir(_ rotina: Rotina) {
        dao.excluir(rotina)
        carregar()
    }
}
