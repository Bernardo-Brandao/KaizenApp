import Foundation
import SQLite

// Backup completo do banco num JSON: exportar gera o arquivo, importar substitui todos os dados.
// O formato tem estruturas próprias (e não os Models) pra continuar estável se os Models mudarem.
struct Backup: Codable {
    static let versaoAtual = 1

    var versao: Int
    var exportadoEm: Date
    var categorias: [CategoriaBackup]
    var rotinas: [RotinaBackup]
    var tarefas: [TarefaBackup]
    var historico: [HistoricoBackup]
    var pausas: [PausaBackup]

    struct CategoriaBackup: Codable, Equatable {
        var id: Int64, nome: String, corHex: String
    }
    struct RotinaBackup: Codable, Equatable {
        var id: Int64, nome: String, descricao: String, frequencia: String, ativa: Bool
        var horarioLembrete: String, lembreteAtivo: Bool, categoriaId: Int64?, diaLembrete: Int
        var icone: String? = nil   // opcional: backups de antes do emoji não têm essa chave
        var diasSemana: String? = nil   // opcional: backups de antes dos dias específicos
    }
    struct TarefaBackup: Codable, Equatable {
        var id: Int64, rotinaId: Int64, nome: String, ordem: Int, dataConclusao: String
        var nota: String? = nil   // opcional: backups de antes das notas não têm essa chave
        var diasSemana: String? = nil
    }
    struct HistoricoBackup: Codable, Equatable {
        var id: Int64, rotinaId: Int64, data: String, totalTarefas: Int, tarefasConcluidas: Int
    }
    struct PausaBackup: Codable, Equatable {
        var id: Int64, rotinaId: Int64, inicio: String, fim: String
    }
}

enum BackupErro: LocalizedError {
    case semBanco
    case versaoNaoSuportada(Int)

    var errorDescription: String? {
        switch self {
        case .semBanco: return "Não foi possível acessar o banco de dados."
        case .versaoNaoSuportada(let versao): return "Este backup é de uma versão mais nova do app (formato \(versao))."
        }
    }
}

enum BackupService {
    // Tabelas e colunas, com os mesmos nomes do DatabaseManager
    private static let categorias = Table("categorias")
    private static let rotinas = Table("rotinas")
    private static let tarefas = Table("tarefas")
    private static let historico = Table("historico_rotina")
    private static let pausas = Table("pausas")

    private static let id = Expression<Int64>("id")
    private static let nome = Expression<String>("nome")
    private static let corHex = Expression<String>("corHex")
    private static let descricao = Expression<String>("descricao")
    private static let frequencia = Expression<String>("frequencia")
    private static let ativa = Expression<Bool>("ativa")
    private static let horarioLembrete = Expression<String>("horarioLembrete")
    private static let lembreteAtivo = Expression<Bool>("lembreteAtivo")
    private static let categoriaId = Expression<Int64?>("categoriaId")
    private static let diaLembrete = Expression<Int>("diaLembrete")
    private static let icone = Expression<String>("icone")
    private static let rotinaId = Expression<Int64>("rotinaId")
    private static let ordem = Expression<Int>("ordem")
    private static let concluidaHoje = Expression<Bool>("concluidaHoje")
    private static let dataConclusao = Expression<String>("dataConclusao")
    private static let data = Expression<String>("data")
    private static let totalTarefas = Expression<Int>("totalTarefas")
    private static let tarefasConcluidas = Expression<Int>("tarefasConcluidas")
    private static let inicio = Expression<String>("inicio")
    private static let fim = Expression<String>("fim")
    private static let nota = Expression<String>("nota")
    private static let diasSemana = Expression<String>("diasSemana")

    // MARK: - Exportar

    static func gerar(db: Connection? = DatabaseManager.shared.db) throws -> Backup {
        guard let db else { throw BackupErro.semBanco }
        return Backup(
            versao: Backup.versaoAtual,
            exportadoEm: Date(),
            categorias: try db.prepare(categorias).map {
                .init(id: $0[id], nome: $0[nome], corHex: $0[corHex])
            },
            rotinas: try db.prepare(rotinas).map {
                .init(id: $0[id], nome: $0[nome], descricao: $0[descricao], frequencia: $0[frequencia],
                      ativa: $0[ativa], horarioLembrete: $0[horarioLembrete], lembreteAtivo: $0[lembreteAtivo],
                      categoriaId: $0[categoriaId], diaLembrete: $0[diaLembrete], icone: $0[icone],
                      diasSemana: $0[diasSemana])
            },
            tarefas: try db.prepare(tarefas).map {
                .init(id: $0[id], rotinaId: $0[rotinaId], nome: $0[nome], ordem: $0[ordem], dataConclusao: $0[dataConclusao],
                      nota: $0[nota], diasSemana: $0[diasSemana])
            },
            historico: try db.prepare(historico).map {
                .init(id: $0[id], rotinaId: $0[rotinaId], data: $0[data],
                      totalTarefas: $0[totalTarefas], tarefasConcluidas: $0[tarefasConcluidas])
            },
            pausas: try db.prepare(pausas).map {
                .init(id: $0[id], rotinaId: $0[rotinaId], inicio: $0[inicio], fim: $0[fim])
            }
        )
    }

    static func json(_ backup: Backup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    // MARK: - Importar

    static func ler(_ dados: Data) throws -> Backup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(Backup.self, from: dados)
        guard backup.versao <= Backup.versaoAtual else {
            throw BackupErro.versaoNaoSuportada(backup.versao)
        }
        return backup
    }

    // Substitui todos os dados pelos do backup, mantendo os ids originais.
    // Tudo numa transação: se qualquer insert falhar, o banco volta ao estado anterior.
    static func restaurar(_ backup: Backup, db: Connection? = DatabaseManager.shared.db) throws {
        guard let db else { throw BackupErro.semBanco }
        try db.transaction {
            for tabela in [pausas, historico, tarefas, rotinas, categorias] {
                try db.run(tabela.delete())
            }
            for c in backup.categorias {
                try db.run(categorias.insert(id <- c.id, nome <- c.nome, corHex <- c.corHex))
            }
            for r in backup.rotinas {
                try db.run(rotinas.insert(
                    id <- r.id, nome <- r.nome, descricao <- r.descricao, frequencia <- r.frequencia,
                    ativa <- r.ativa, horarioLembrete <- r.horarioLembrete, lembreteAtivo <- r.lembreteAtivo,
                    categoriaId <- r.categoriaId, diaLembrete <- r.diaLembrete,
                    icone <- (r.icone ?? ""), diasSemana <- (r.diasSemana ?? "")
                ))
            }
            for t in backup.tarefas {
                try db.run(tarefas.insert(
                    id <- t.id, rotinaId <- t.rotinaId, nome <- t.nome, ordem <- t.ordem,
                    concluidaHoje <- !t.dataConclusao.isEmpty, dataConclusao <- t.dataConclusao,
                    nota <- (t.nota ?? ""), diasSemana <- (t.diasSemana ?? "")
                ))
            }
            for h in backup.historico {
                try db.run(historico.insert(
                    id <- h.id, rotinaId <- h.rotinaId, data <- h.data,
                    totalTarefas <- h.totalTarefas, tarefasConcluidas <- h.tarefasConcluidas
                ))
            }
            for p in backup.pausas {
                try db.run(pausas.insert(id <- p.id, rotinaId <- p.rotinaId, inicio <- p.inicio, fim <- p.fim))
            }
        }
    }
}
