import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

struct AjustesView: View {
    @State private var mostrarImportador = false
    @State private var backupPendente: Backup?
    @State private var mensagem: Mensagem?
    @AppStorage("resumoSemanalAtivo") private var resumoSemanalAtivo = true
    @AppStorage(NotificationManager.chaveFimDoDia) private var fimDoDia = NotificationManager.horarioFimDoDiaPadrao
    @AppStorage(Bloqueio.chaveAtivo) private var bloqueioAtivo = false

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
                    Text("O backup guarda rotinas, tarefas, categorias, histórico, pausas, dias pulados e o que foi feito em cada dia num arquivo. Importar substitui todos os dados atuais.")
                }

                Section {
                    Toggle(isOn: $resumoSemanalAtivo) {
                        Label("Resumo semanal", systemImage: "calendar")
                    }
                    .onChange(of: resumoSemanalAtivo) { _, ativo in
                        NotificationManager.shared.agendarResumoSemanal(ativo: ativo)
                    }
                    CampoHorario(horario: $fimDoDia, titulo: "Lembrete do fim do dia", icone: "moon")
                        .onChange(of: fimDoDia) { _, _ in
                            NotificationManager.shared.agendarFimDoDia()
                        }
                } header: {
                    Text("Notificações")
                } footer: {
                    Text("Resumo semanal: todo domingo às 19h. Fim do dia: só avisa se ainda faltar alguma tarefa das rotinas diárias.")
                }

                Section {
                    Toggle(isOn: Binding(get: { bloqueioAtivo }, set: alternarBloqueio)) {
                        Label("Bloquear com \(Bloqueio.nomeBiometria)", systemImage: Bloqueio.iconeBiometria)
                    }
                } header: {
                    Text("Privacidade")
                } footer: {
                    Text("Pede o \(Bloqueio.nomeBiometria) sempre que você abrir o Kaizen. Se não reconhecer, dá para usar o código do iPhone.")
                }

                Section("Organização") {
                    NavigationLink {
                        CategoriasView()
                    } label: {
                        Label("Categorias", systemImage: "tag")
                    }
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

    private func alternarBloqueio(_ ligar: Bool) {
        guard Bloqueio.disponivel else {
            mensagem = Mensagem(titulo: "Bloqueio indisponível",
                                texto: "Configure um código no iPhone (Ajustes › Face ID e Código) para usar o bloqueio.")
            return
        }
        Task {
            if await Bloqueio.autenticar(motivo: ligar ? "Ativar o bloqueio do Kaizen" : "Desativar o bloqueio do Kaizen") {
                bloqueioAtivo = ligar
            }
        }
    }

    private func abrirArquivo(_ resultado: Result<URL, Error>) {
        do {
            let url = try resultado.get()
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
