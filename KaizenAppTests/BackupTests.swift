import Foundation
import Testing
@testable import KaizenApp

// Usa um banco em memória com o mesmo esquema do app — não toca nos dados reais
@MainActor
struct BackupTests {
    private func exemplo() -> Backup {
        Backup(
            versao: Backup.versaoAtual,
            exportadoEm: Date(timeIntervalSince1970: 1_790_000_000),
            categorias: [.init(id: 3, nome: "Saúde", corHex: "34C759")],
            rotinas: [
                .init(id: 10, nome: "Manhã", descricao: "Começar o dia", frequencia: "Diária", ativa: true,
                      horarioLembrete: "07:30", lembreteAtivo: true, categoriaId: 3, diaLembrete: 1),
                .init(id: 11, nome: "Faxina", descricao: "", frequencia: "Semanal", ativa: false,
                      horarioLembrete: "", lembreteAtivo: false, categoriaId: nil, diaLembrete: 7),
            ],
            tarefas: [
                .init(id: 100, rotinaId: 10, nome: "Água", ordem: 0, dataConclusao: "2026-10-20", nota: "2 litros"),
                .init(id: 101, rotinaId: 10, nome: "Alongar", ordem: 1, dataConclusao: "", nota: ""),
            ],
            historico: [.init(id: 1, rotinaId: 10, data: "2026-10-19", totalTarefas: 2, tarefasConcluidas: 2)],
            pausas: [.init(id: 1, rotinaId: 11, inicio: "2026-10-15", fim: "")]
        )
    }

    @Test func restaurarEExportarDevolveOsMesmosDados() throws {
        let db = DatabaseManager.bancoEmMemoria()
        let original = exemplo()

        try BackupService.restaurar(original, db: db)
        let exportado = try BackupService.gerar(db: db)

        #expect(exportado.categorias == original.categorias)
        #expect(exportado.rotinas == original.rotinas)
        #expect(exportado.tarefas == original.tarefas)
        #expect(exportado.historico == original.historico)
        #expect(exportado.pausas == original.pausas)
    }

    @Test func restaurarSubstituiOsDadosAnteriores() throws {
        let db = DatabaseManager.bancoEmMemoria()
        try BackupService.restaurar(exemplo(), db: db)

        var menor = exemplo()
        menor.rotinas = [menor.rotinas[0]]
        menor.tarefas = []
        menor.pausas = []
        try BackupService.restaurar(menor, db: db)

        let exportado = try BackupService.gerar(db: db)
        #expect(exportado.rotinas.map(\.id) == [10])
        #expect(exportado.tarefas.isEmpty)
        #expect(exportado.pausas.isEmpty)
    }

    @Test func jsonIdaEVolta() throws {
        let original = exemplo()
        let lido = try BackupService.ler(BackupService.json(original))
        #expect(lido.rotinas == original.rotinas)
        #expect(lido.exportadoEm == original.exportadoEm)
    }

    @Test func recusaVersaoMaisNova() throws {
        var futuro = exemplo()
        futuro.versao = Backup.versaoAtual + 1
        let dados = try BackupService.json(futuro)
        #expect(throws: BackupErro.self) { try BackupService.ler(dados) }
    }

    @Test func leBackupAntigoSemNotas() throws {
        // Formato de antes das notas: tarefa sem a chave "nota"
        let antigo = """
        {"versao": 1, "exportadoEm": "2026-10-22T12:00:00Z", "categorias": [], "pausas": [], "historico": [],
         "rotinas": [{"id": 1, "nome": "Manhã", "descricao": "", "frequencia": "Diária", "ativa": true,
                      "horarioLembrete": "", "lembreteAtivo": false, "diaLembrete": 1}],
         "tarefas": [{"id": 5, "rotinaId": 1, "nome": "Água", "ordem": 0, "dataConclusao": ""}]}
        """
        let backup = try BackupService.ler(Data(antigo.utf8))
        #expect(backup.tarefas.first?.nota == nil)

        let db = DatabaseManager.bancoEmMemoria()
        try BackupService.restaurar(backup, db: db)
        #expect(try BackupService.gerar(db: db).tarefas.first?.nota == "")
    }

    @Test func recusaArquivoQueNaoEhBackup() {
        #expect(throws: (any Error).self) { try BackupService.ler(Data("{\"oi\": 1}".utf8)) }
    }
}
