//
//  RotinaViewModel.swift
//  KaizenApp
//
//  Created by Bernardo Brandão on 05/08/26.
//

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

    func excluir(_ rotina: Rotina) {
        dao.excluir(rotina)
        carregar()
    }
}
