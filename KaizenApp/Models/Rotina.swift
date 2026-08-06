//
//  Rotina.swift
//  KaizenApp
//
//  Created by Bernardo Brandão on 05/08/26.
//

import Foundation

struct Rotina: Identifiable {
    var id: Int64?
    var nome: String
    var descricao: String
    var frequencia: String   // "Diária", "Semanal", "Mensal"
    var ativa: Bool
}
