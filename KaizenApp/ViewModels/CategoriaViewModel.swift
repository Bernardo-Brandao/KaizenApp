import Foundation
import Combine

// Lista as categorias e permite criar, editar e excluir
class CategoriaViewModel: ObservableObject {
    @Published var categorias: [Categoria] = []
    private let dao = CategoriaDAO()

    func carregar() {
        categorias = dao.listarTodas()
    }

    func adicionar(nome: String, corHex: String) {
        let nova = Categoria(id: nil, nome: nome, corHex: corHex)
        dao.inserir(nova)
        carregar()
    }

    func excluir(_ categoria: Categoria) {
        dao.excluir(categoria)
        carregar()
    }
}
