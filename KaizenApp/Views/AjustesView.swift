import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

struct AjustesView: View {
    @State private var mostrarImportador = false
    @State private var backupPendente: Backup?        // lido do arquivo, esperando confirmação
    @State private var mensagem: Mensagem?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ShareLink(item: ArquivoBackup(), preview: SharePreview("Backup do Kaizen")) {
                        Label("Exportar backup", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        mostrarImportador = true
                    } label: {
                        Label("Importar backup", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("O backup guarda rotinas, tarefas, categorias, histórico e pausas num arquivo. Importar substitui todos os dados atuais.")
                }

                Section("Sobre") {
                    LabeledContent("Versão", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                }
            }
            .navigationTitle("Ajustes")
            .fileImporter(isPresented: $mostrarImportador, allowedContentTypes: [.json]) { resultado in
                abrirArquivo(resultado)
            }
            .confirmationDialog(
                "Substituir todos os dados?",
                isPresented: Binding(get: { backupPendente != nil }, set: { if !$0 { backupPendente = nil } }),
                titleVisibility: .visible,
                presenting: backupPendente
            ) { backup in
                Button("Substituir dados", role: .destructive) { restaurar(backup) }
                Button("Cancelar", role: .cancel) {}
            } message: { backup in
                Text("O backup tem \(backup.rotinas.count) rotinas e \(backup.tarefas.count) tarefas, exportado em \(backup.exportadoEm.formatted(date: .abbreviated, time: .shortened)). Os dados atuais serão apagados.")
            }
            .alert(item: $mensagem) { mensagem in
                Alert(title: Text(mensagem.titulo), message: Text(mensagem.texto))
            }
        }
    }

    private func abrirArquivo(_ resultado: Result<URL, Error>) {
        do {
            let url = try resultado.get()
            // Arquivos de fora do app (Arquivos, iCloud) precisam de acesso liberado
            let acessou = url.startAccessingSecurityScopedResource()
            defer { if acessou { url.stopAccessingSecurityScopedResource() } }
            backupPendente = try BackupService.ler(Data(contentsOf: url))
        } catch {
            mensagem = Mensagem(titulo: "Não foi possível abrir o backup",
                                texto: (error as? LocalizedError)?.errorDescription ?? "O arquivo não é um backup válido do Kaizen.")
        }
    }

    private func restaurar(_ backup: Backup) {
        do {
            try BackupService.restaurar(backup)
            // Lembretes e widget passam a refletir os dados importados
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            NotificationManager.shared.reagendarTodos()
            WidgetSync.atualizar()
            mensagem = Mensagem(titulo: "Backup importado", texto: "\(backup.rotinas.count) rotinas restauradas.")
        } catch {
            mensagem = Mensagem(titulo: "Falha ao importar", texto: "Nenhum dado foi alterado. \(error.localizedDescription)")
        }
    }
}

private struct Mensagem: Identifiable {
    let id = UUID()
    let titulo: String
    let texto: String
}

// Arquivo gerado na hora em que o usuário escolhe compartilhar
struct ArquivoBackup: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { _ in
            let dados = try await MainActor.run { try BackupService.json(BackupService.gerar()) }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("Kaizen-backup-\(await MainActor.run { DataUtil.hoje() }).json")
            try dados.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
