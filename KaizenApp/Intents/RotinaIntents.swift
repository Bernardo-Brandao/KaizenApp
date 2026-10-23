import AppIntents

// Ações da Siri e do app Atalhos. Textos em inglês: é o idioma do projeto e da Siri do usuário.

// "How are my routines?" — resumo do período atual de todas as rotinas ativas
struct ResumoRotinasIntent: AppIntent {
    static let title: LocalizedStringResource = "Routines Summary"
    static let description = IntentDescription("Tells how many routines you completed and which one is next.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let texto = Self.resumo(ResumoWidget.carregar().filter { $0.total > 0 }, agora: .now)
        return .result(value: texto, dialog: "\(texto)")
    }

    static func resumo(_ rotinas: [ResumoRotina], agora: Date) -> String {
        guard !rotinas.isEmpty else { return "You don't have any routines with tasks yet." }
        let completas = rotinas.filter { $0.completa(em: agora) }.count
        let pendentes = rotinas.filter { !$0.completa(em: agora) }

        if pendentes.isEmpty {
            return rotinas.count == 1
                ? "All done! You completed your routine."
                : "All done! You completed all \(rotinas.count) routines."
        }
        let proxima = pendentes[0]
        let progresso = "\(proxima.concluidas(em: agora)) of \(proxima.total) tasks"
        let falta = pendentes.count == 1
            ? "\(proxima.nome) is left, with \(progresso) done."
            : "\(pendentes.count) are left. Next up is \(proxima.nome), with \(progresso) done."
        return "You completed \(completas) of \(rotinas.count) routines. \(falta)"
    }
}

// "Mark <routine> as done" — conclui todas as tarefas do período, igual ao botão da notificação
struct ConcluirRotinaIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Routine as Done"
    static let description = IntentDescription("Completes all of the routine's tasks for the current period.")

    @Parameter(title: "Routine", requestValueDialog: "Which routine?")
    var rotina: RotinaEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        ConclusaoTarefa.concluirTodas(rotinaId: Int64(rotina.id))
        WidgetSync.atualizar()
        return .result(dialog: "Done! \(rotina.nome) is complete.")
    }
}

// "<routine> progress" — quantas tarefas da rotina já foram feitas no período
struct ProgressoRotinaIntent: AppIntent {
    static let title: LocalizedStringResource = "Routine Progress"
    static let description = IntentDescription("Tells how many of the routine's tasks you did in the current period.")

    @Parameter(title: "Routine", requestValueDialog: "Which routine?")
    var rotina: RotinaEntity

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let frequencia = RotinaDAO().buscar(id: Int64(rotina.id))?.frequencia ?? "Diária"
        let tarefas = TarefaDAO().listarPorRotina(Int64(rotina.id), frequencia: frequencia)
        let feitas = tarefas.filter(\.concluidaHoje).count
        let periodo = switch frequencia {
        case "Semanal": "this week"
        case "Mensal": "this month"
        default: "today"
        }
        let texto = tarefas.isEmpty
            ? "\(rotina.nome) doesn't have any tasks yet."
            : "\(rotina.nome): \(feitas) of \(tarefas.count) tasks done \(periodo)."
        return .result(value: texto, dialog: "\(texto)")
    }
}

// Frases da Siri. Toda frase precisa ter o nome do app.
struct KaizenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ResumoRotinasIntent(),
            phrases: [
                "How are my routines in \(.applicationName)",
                "\(.applicationName) summary",
                "My routines in \(.applicationName)",
            ],
            shortTitle: "Routines Summary",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: ConcluirRotinaIntent(),
            phrases: [
                "Mark \(\.$rotina) as done in \(.applicationName)",
                "Complete \(\.$rotina) in \(.applicationName)",
                "Mark a routine as done in \(.applicationName)",
            ],
            shortTitle: "Mark as Done",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: ProgressoRotinaIntent(),
            phrases: [
                "\(\.$rotina) progress in \(.applicationName)",
                "How is \(\.$rotina) going in \(.applicationName)",
            ],
            shortTitle: "Routine Progress",
            systemImageName: "chart.bar"
        )
    }
}
