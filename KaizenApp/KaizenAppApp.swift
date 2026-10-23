import SwiftUI

@main
struct KaizenAppApp: App {
    @State private var abaSelecionada = Aba.rotinas
    @State private var rotinaParaAbrir: Int64?   // vem de um link kaizen://rotina/<id> (widget)

    enum Aba { case rotinas, categorias, ajustes }

    init() {
        NotificationManager.shared.solicitarPermissao()
        NotificationManager.shared.reagendarTodos()
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $abaSelecionada) {
                ListaRotinasView(rotinaParaAbrir: $rotinaParaAbrir)
                    .tabItem {
                        Label("Rotinas", systemImage: "checklist")
                    }
                    .tag(Aba.rotinas)

                CategoriasView()
                    .tabItem {
                        Label("Categorias", systemImage: "tag")
                    }
                    .tag(Aba.categorias)

                AjustesView()
                    .tabItem {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                    .tag(Aba.ajustes)
            }
            .tint(AppTheme.primary)
            // Links do widget: kaizen://rotinas abre a lista; kaizen://rotina/<id> abre a rotina
            .onOpenURL { url in
                guard url.scheme == "kaizen" else { return }
                abaSelecionada = .rotinas
                if url.host == "rotina", let id = Int64(url.lastPathComponent) {
                    rotinaParaAbrir = id
                }
            }
        }
    }
}
