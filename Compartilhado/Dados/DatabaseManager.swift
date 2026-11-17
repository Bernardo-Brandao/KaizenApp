import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    var db: Connection?

    private init() {
        do {
            let path = Self.caminhoDoBanco()
            db = try Connection(path)
            db?.busyTimeout = 5
            print("Banco em: \(path)")
            Self.prepararEsquema(db)
        } catch {
            print("Erro ao conectar no banco: \(error)")
        }
    }

    private static func caminhoDoBanco() -> String {
        let arquivo = "kaizen.sqlite3"
        let documentos = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let grupo = AppGroup.pasta else {
            return documentos.appendingPathComponent(arquivo).path
        }

        let antigo = documentos.appendingPathComponent(arquivo)
        let novo = grupo.appendingPathComponent(arquivo)
        let fm = FileManager.default
        if fm.fileExists(atPath: antigo.path) {
            for sufixo in ["", "-wal", "-shm"] {
                try? fm.removeItem(at: URL(fileURLWithPath: novo.path + sufixo))
            }
            do {
                try fm.moveItem(at: antigo, to: novo)
            } catch {
                print("Erro ao mover o banco pro App Group: \(error)")
                return antigo.path
            }
            for sufixo in ["-wal", "-shm"] {
                try? fm.moveItem(at: URL(fileURLWithPath: antigo.path + sufixo),
                                 to: URL(fileURLWithPath: novo.path + sufixo))
            }
        }
        return novo.path
    }

    static func bancoEmMemoria() -> Connection? {
        let db = try? Connection(.inMemory)
        prepararEsquema(db)
        return db
    }

    private static func prepararEsquema(_ db: Connection?) {
        criarTabelas(db)
        migrarTabelas(db)
    }

    private static func criarTabelas(_ db: Connection?) {
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
        let icone = Expression<String>("icone")

        let rotinaId = Expression<Int64>("rotinaId")
        let ordem = Expression<Int>("ordem")
        let concluidaHoje = Expression<Bool>("concluidaHoje")
        let dataConclusao = Expression<String>("dataConclusao")
        let nota = Expression<String>("nota")

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
            t.column(icone, defaultValue: "")
        })

        try? db?.run(tarefas.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(rotinaId)
            t.column(nome)
            t.column(ordem)
            t.column(concluidaHoje)
            t.column(dataConclusao, defaultValue: "")
            t.column(nota, defaultValue: "")
            t.column(Expression<String>("horario"), defaultValue: "")
            t.column(Expression<String>("tipo"), defaultValue: "check")
            t.column(Expression<String>("unidade"), defaultValue: "")
            t.column(Expression<Double?>("meta"))
            t.column(Expression<String>("saude"), defaultValue: "")
        })

        let registros = Table("registros_tarefa")
        let tarefaId = Expression<Int64>("tarefaId")
        try? db?.run(registros.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(tarefaId)
            t.column(Expression<String>("data"))
            t.column(Expression<Double>("valor"))
        })
        try? db?.run(registros.createIndex(tarefaId, Expression<String>("data"), unique: true, ifNotExists: true))

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

        let conclusoes = Table("conclusoes")
        let tarefaIdConclusao = Expression<Int64>("tarefaId")
        let periodoConclusao = Expression<String>("periodo")
        if (try? db?.run(conclusoes.create { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(tarefaIdConclusao)
            t.column(periodoConclusao)
        })) != nil {
            try? db?.run(conclusoes.createIndex(tarefaIdConclusao, periodoConclusao, unique: true, ifNotExists: true))
            preencherConclusoes(db)
        }

        let pulos = Table("pulos")
        try? db?.run(pulos.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(rotinaId)
            t.column(Expression<String>("periodo"))
        })
        try? db?.run(pulos.createIndex(rotinaId, Expression<String>("periodo"), unique: true, ifNotExists: true))

        try? db?.run(historico.createIndex(rotinaId, data, unique: true, ifNotExists: true))
    }

    private static func preencherConclusoes(_ db: Connection?) {
        guard let linhas = try? db?.prepare("""
            SELECT tarefas.id, tarefas.dataConclusao, rotinas.frequencia FROM tarefas
            JOIN rotinas ON rotinas.id = tarefas.rotinaId WHERE tarefas.dataConclusao != ''
            """) else { return }
        for linha in linhas {
            guard let tarefaId = linha[0] as? Int64, let data = linha[1] as? String,
                  let frequencia = linha[2] as? String else { continue }
            try? db?.run("INSERT OR IGNORE INTO conclusoes (tarefaId, periodo) VALUES (?, ?)",
                         tarefaId, DataUtil.inicioPeriodo(data, frequencia: frequencia))
        }
    }

    private static func migrarTabelas(_ db: Connection?) {
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN horarioLembrete TEXT DEFAULT ''")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN lembreteAtivo INTEGER DEFAULT 0")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN categoriaId INTEGER")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN diaLembrete INTEGER DEFAULT 1")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN icone TEXT DEFAULT ''")
        try? db?.execute("ALTER TABLE tarefas ADD COLUMN dataConclusao TEXT DEFAULT ''")
        try? db?.execute("ALTER TABLE tarefas ADD COLUMN nota TEXT DEFAULT ''")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN diasSemana TEXT DEFAULT ''")
        try? db?.execute("ALTER TABLE tarefas ADD COLUMN diasSemana TEXT DEFAULT ''")

        if (try? db?.execute("ALTER TABLE tarefas ADD COLUMN horario TEXT DEFAULT ''")) != nil {
            try? db?.execute("""
                UPDATE tarefas SET horario = (SELECT horarioLembrete FROM rotinas WHERE rotinas.id = tarefas.rotinaId)
                WHERE horario = '' AND rotinaId IN
                    (SELECT id FROM rotinas WHERE lembreteAtivo = 1 AND horarioLembrete != '')
                """)
            try? db?.execute("UPDATE rotinas SET lembreteAtivo = 0, horarioLembrete = ''")
        }

        try? db?.execute("ALTER TABLE tarefas ADD COLUMN tipo TEXT DEFAULT 'check'")
        try? db?.execute("ALTER TABLE tarefas ADD COLUMN unidade TEXT DEFAULT ''")
        try? db?.execute("ALTER TABLE tarefas ADD COLUMN meta REAL")
        try? db?.execute("ALTER TABLE tarefas ADD COLUMN saude TEXT DEFAULT ''")

        try? db?.execute("DELETE FROM tarefas WHERE rotinaId NOT IN (SELECT id FROM rotinas)")
        try? db?.execute("DELETE FROM historico_rotina WHERE rotinaId NOT IN (SELECT id FROM rotinas)")
        try? db?.execute("DELETE FROM pausas WHERE rotinaId NOT IN (SELECT id FROM rotinas)")
        try? db?.execute("DELETE FROM registros_tarefa WHERE tarefaId NOT IN (SELECT id FROM tarefas)")
        try? db?.execute("DELETE FROM pulos WHERE rotinaId NOT IN (SELECT id FROM rotinas)")
        try? db?.execute("DELETE FROM conclusoes WHERE tarefaId NOT IN (SELECT id FROM tarefas)")
    }
}
