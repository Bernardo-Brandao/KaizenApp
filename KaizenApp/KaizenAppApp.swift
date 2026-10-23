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

                AjustesView()
                    .tabItem {
                        Label("Ajustes", systemImage: "gearshape")
                    }
            }
            .tint(AppTheme.primary)
        }
    }
}
