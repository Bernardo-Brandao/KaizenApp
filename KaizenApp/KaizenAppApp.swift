import SwiftUI

@main
struct KaizenAppApp: App {
    init() {
        NotificationManager.shared.solicitarPermissao()
        NotificationManager.shared.reagendarTodos()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                ListaRotinasView()
                    .tabItem {
                        Label("Rotinas", systemImage: "checklist")
                    }

                CategoriasView()
                    .tabItem {
                        Label("Categorias", systemImage: "tag")
                    }
            }
            .tint(AppTheme.primary)
        }
    }
}
