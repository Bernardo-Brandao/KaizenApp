//
//  Tarefa.swift
//  KaizenApp
//
//  Created by Bernardo Brandão on 05/08/26.
//

import Foundation

struct Tarefa: Identifiable {
    var id: Int64?
    var rotinaId: Int64
    var nome: String
    var ordem: Int
    var concluidaHoje: Bool
}
