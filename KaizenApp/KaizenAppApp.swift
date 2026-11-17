import SwiftUI

@main
struct KaizenAppApp: App {
    @State private var abaSelecionada = Aba.hoje
    @State private var rotinaParaAbrir: Int64?
    @State private var mostrarSemana = false
    @StateObject private var bloqueio = Bloqueio()
    @AppStorage("boasVindasVistas") private var boasVindasVistas = false
    @State private var mostrarBoasVindas = false
    @Environment(\.scenePhase) private var scenePhase

    enum Aba { case hoje, resumo, rotinas, ajustes }

    init() {
        NotificacaoDelegate.shared.registrar()
        if UserDefaults.standard.bool(forKey: "boasVindasVistas") {
            NotificationManager.shared.solicitarPermissao()
        }
        NotificationManager.shared.reagendarTodos()
        NotificationManager.shared.agendarResumoSemanal(ativo: UserDefaults.standard.object(forKey: "resumoSemanalAtivo") as? Bool ?? true)
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $abaSelecionada) {
                HojeView(abaSelecionada: $abaSelecionada)
                    .comBarraInferior($abaSelecionada)
                    .tag(Aba.hoje)

                ResumoView(abaSelecionada: $abaSelecionada, mostrarSemana: $mostrarSemana)
                    .comBarraInferior($abaSelecionada)
                    .tag(Aba.resumo)

                ListaRotinasView(rotinaParaAbrir: $rotinaParaAbrir)
                    .comBarraInferior($abaSelecionada)
                    .tag(Aba.rotinas)

                AjustesView()
                    .comBarraInferior($abaSelecionada)
                    .tag(Aba.ajustes)
            }
            .tint(Paleta.destaque)
            .overlay {
                if bloqueio.bloqueado {
                    TelaBloqueio { Task { await bloqueio.desbloquear() } }
                        .transition(.opacity)
                }
            }
            .task {
                if !boasVindasVistas {
                    if RotinaDAO().listarTodas().isEmpty {
                        mostrarBoasVindas = true
                    } else {
                        boasVindasVistas = true
                    }
                }
                await bloqueio.aoFicarAtivo()
            }
            .fullScreenCover(isPresented: $mostrarBoasVindas) {
                BoasVindasView { aba in
                    boasVindasVistas = true
                    abaSelecionada = aba
                    mostrarBoasVindas = false
                }
            }
            .onChange(of: scenePhase) { _, fase in
                switch fase {
                case .background:
                    bloqueio.bloquear()
                    WidgetSync.atualizar()
                case .active: Task { await bloqueio.aoFicarAtivo() }
                default: break
                }
            }
            .onOpenURL { url in
                guard url.scheme == "kaizen" else { return }
                if url.host == "hoje" {
                    abaSelecionada = .hoje
                    return
                }
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
