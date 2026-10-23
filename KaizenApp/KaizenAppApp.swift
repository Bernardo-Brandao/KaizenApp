import SwiftUI

@main
struct KaizenAppApp: App {
    @State private var abaSelecionada = Aba.resumo
    @State private var rotinaParaAbrir: Int64?   // vem de um link kaizen://rotina/<id> (widget)
    @State private var mostrarSemana = false     // kaizen://semana (notificação do resumo semanal)

    enum Aba { case resumo, rotinas, premios, ajustes }

    init() {
        NotificacaoDelegate.shared.registrar()
        NotificationManager.shared.solicitarPermissao()
        NotificationManager.shared.reagendarTodos()
        NotificationManager.shared.agendarResumoSemanal(ativo: UserDefaults.standard.object(forKey: "resumoSemanalAtivo") as? Bool ?? true)
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $abaSelecionada) {
                ResumoView(abaSelecionada: $abaSelecionada, mostrarSemana: $mostrarSemana)
                    .tabItem {
                        Label("Resumo", systemImage: "circle.circle")
                    }
                    .tag(Aba.resumo)

                ListaRotinasView(rotinaParaAbrir: $rotinaParaAbrir)
                    .tabItem {
                        Label("Rotinas", systemImage: "checklist")
                    }
                    .tag(Aba.rotinas)

                PremiosView()
                    .tabItem {
                        Label("Prêmios", systemImage: "trophy")
                    }
                    .tag(Aba.premios)

                AjustesView()
                    .tabItem {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                    .tag(Aba.ajustes)
            }
            .tint(AppTheme.primary)
            // Links: kaizen://rotinas abre a lista; kaizen://rotina/<id> abre a rotina;
            // kaizen://semana abre o resumo da semana
            .onOpenURL { url in
                guard url.scheme == "kaizen" else { return }
                if url.host == "semana" {
                    abaSelecionada = .resumo
                    mostrarSemana = true
                    return
                }
                abaSelecionada = .rotinas
                if url.host == "rotina", let id = Int64(url.lastPathComponent) {
                    rotinaParaAbrir = id
                }
            }
        }
    }
}
