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
            migrarTabelas()
        } catch {
            print("Erro ao conectar no banco: \(error)")
        }
    }

    private func criarTabelas() {
        let rotinas = Table("rotinas")
        let tarefas = Table("tarefas")
        let categorias = Table("categorias")
        let historico = Table("historico_rotina")
        let pausas = Table("pausas")

        let id = Expression<Int64>("id")
        let nome = Expression<String>("nome")
        let descricao = Expression<String>("descricao")
        let frequencia = Expression<String>("frequencia")
        let ativa = Expression<Bool>("ativa")
        let horarioLembrete = Expression<String>("horarioLembrete")
        let lembreteAtivo = Expression<Bool>("lembreteAtivo")
        let categoriaId = Expression<Int64?>("categoriaId")
        let diaLembrete = Expression<Int>("diaLembrete")

        let rotinaId = Expression<Int64>("rotinaId")
        let ordem = Expression<Int>("ordem")
        let concluidaHoje = Expression<Bool>("concluidaHoje")
        let dataConclusao = Expression<String>("dataConclusao")

        let corHex = Expression<String>("corHex")

        let data = Expression<String>("data")
        let totalTarefas = Expression<Int>("totalTarefas")
        let tarefasConcluidas = Expression<Int>("tarefasConcluidas")

        try? db?.run(rotinas.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(nome)
            t.column(descricao)
            t.column(frequencia)
            t.column(ativa)
            t.column(horarioLembrete, defaultValue: "")
            t.column(lembreteAtivo, defaultValue: false)
            t.column(categoriaId)
            t.column(diaLembrete, defaultValue: 1)
        })

        try? db?.run(tarefas.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(rotinaId)
            t.column(nome)
            t.column(ordem)
            t.column(concluidaHoje)
            t.column(dataConclusao, defaultValue: "")
        })

        try? db?.run(categorias.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(nome)
            t.column(corHex)
        })

        try? db?.run(historico.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(rotinaId)
            t.column(data)
            t.column(totalTarefas)
            t.column(tarefasConcluidas)
        })

        let inicio = Expression<String>("inicio")
        let fim = Expression<String>("fim")

        try? db?.run(pausas.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(rotinaId)
            t.column(inicio)
            t.column(fim, defaultValue: "")
        })

        // Garante que só existe um registro por rotina/dia — evita duplicar linhas
        try? db?.run(historico.createIndex(rotinaId, data, unique: true, ifNotExists: true))
    }

    private func migrarTabelas() {
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN horarioLembrete TEXT DEFAULT ''")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN lembreteAtivo INTEGER DEFAULT 0")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN categoriaId INTEGER")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN diaLembrete INTEGER DEFAULT 1")
        // Dia em que a tarefa foi concluída ("yyyy-MM-dd"); vazio se não concluída
        try? db?.execute("ALTER TABLE tarefas ADD COLUMN dataConclusao TEXT DEFAULT ''")

        // Limpa tarefas e histórico de rotinas que já foram excluídas
        try? db?.execute("DELETE FROM tarefas WHERE rotinaId NOT IN (SELECT id FROM rotinas)")
        try? db?.execute("DELETE FROM historico_rotina WHERE rotinaId NOT IN (SELECT id FROM rotinas)")
        try? db?.execute("DELETE FROM pausas WHERE rotinaId NOT IN (SELECT id FROM rotinas)")
    }
}
