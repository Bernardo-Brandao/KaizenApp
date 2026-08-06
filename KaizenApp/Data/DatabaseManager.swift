//
//  DatabaseManager.swift
//  KaizenApp
//
//  Created by Bernardo Brandão on 05/08/26.
//

import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    var db: Connection?

    private init() {
        do {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("kaizen.sqlite3").path
            db = try Connection(path)
            print("Banco criado em: \(path)")
            criarTabelas()
        } catch {
            print("Erro ao conectar no banco: \(error)")
        }
    }

    private func criarTabelas() {
        let rotinas = Table("rotinas")
        let tarefas = Table("tarefas")
        let categorias = Table("categorias")

        let id = Expression<Int64>("id")
        let nome = Expression<String>("nome")
        let descricao = Expression<String>("descricao")
        let frequencia = Expression<String>("frequencia")
        let ativa = Expression<Bool>("ativa")

        let rotinaId = Expression<Int64>("rotinaId")
        let ordem = Expression<Int>("ordem")
        let concluidaHoje = Expression<Bool>("concluidaHoje")

        let corHex = Expression<String>("corHex")

        try? db?.run(rotinas.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(nome)
            t.column(descricao)
            t.column(frequencia)
            t.column(ativa)
        })

        try? db?.run(tarefas.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(rotinaId)
            t.column(nome)
            t.column(ordem)
            t.column(concluidaHoje)
        })

        try? db?.run(categorias.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(nome)
            t.column(corHex)
        })
    }
}
