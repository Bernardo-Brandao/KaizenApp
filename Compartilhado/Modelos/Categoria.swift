import Foundation

// Categoria de rotina, com nome e cor (a cor aparece na capa e nos indicadores)
struct Categoria: Identifiable {
    var id: Int64?
    var nome: String
    var corHex: String
}
