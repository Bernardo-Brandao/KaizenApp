import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    var db: Connection?

    private init() {
        do {
            let path = Self.caminhoDoBanco()
            db = try Connection(path)
            // App e widget usam o mesmo arquivo; espera em vez de falhar se o outro estiver escrevendo
            db?.busyTimeout = 5
            print("Banco em: \(path)")
            Self.prepararEsquema(db)
        } catch {
            print("Erro ao conectar no banco: \(error)")
        }
    }

    // O banco fica no App Group pra o widget também acessar.
    // Versões anteriores guardavam em Documentos: se o arquivo antigo existir, ele é movido pro grupo.
    // Ele substitui um banco do grupo que já exista, porque esse só pode ter sido criado vazio pelo widget
    // (o widget não enxerga Documentos do app e não cria rotinas). Depois de movido, não roda mais.
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
            // Arquivos do banco do grupo (vazio, criado pelo widget) saem antes
            for sufixo in ["", "-wal", "-shm"] {
                try? fm.removeItem(at: URL(fileURLWithPath: novo.path + sufixo))
            }
            do {
                try fm.moveItem(at: antigo, to: novo)
            } catch {
                print("Erro ao mover o banco pro App Group: \(error)")
                return antigo.path   // continua usando o antigo; tenta de novo na próxima abertura
            }
            // Arquivos auxiliares do SQLite vão junto quando existem
            for sufixo in ["-wal", "-shm"] {
                try? fm.moveItem(at: URL(fileURLWithPath: antigo.path + sufixo),
                                 to: URL(fileURLWithPath: novo.path + sufixo))
            }
        }
        return novo.path
    }

    // Banco temporário em memória, com o mesmo esquema — usado nos testes
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

    private static func migrarTabelas(_ db: Connection?) {
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN horarioLembrete TEXT DEFAULT ''")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN lembreteAtivo INTEGER DEFAULT 0")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN categoriaId INTEGER")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN diaLembrete INTEGER DEFAULT 1")
        try? db?.execute("ALTER TABLE rotinas ADD COLUMN icone TEXT DEFAULT ''")
        // Dia em que a tarefa foi concluída ("yyyy-MM-dd"); vazio se não concluída
        try? db?.execute("ALTER TABLE tarefas ADD COLUMN dataConclusao TEXT DEFAULT ''")
        try? db?.execute("ALTER TABLE tarefas ADD COLUMN nota TEXT DEFAULT ''")

        // Limpa tarefas e histórico de rotinas que já foram excluídas
        try? db?.execute("DELETE FROM tarefas WHERE rotinaId NOT IN (SELECT id FROM rotinas)")
        try? db?.execute("DELETE FROM historico_rotina WHERE rotinaId NOT IN (SELECT id FROM rotinas)")
        try? db?.execute("DELETE FROM pausas WHERE rotinaId NOT IN (SELECT id FROM rotinas)")
    }
}
