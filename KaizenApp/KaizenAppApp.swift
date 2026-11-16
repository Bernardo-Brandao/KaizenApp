import SwiftUI

@main
// Ponto de entrada do app: monta as abas, a barra inferior, o bloqueio com Face ID,
// as boas-vindas e trata os links que vêm do widget e das notificações
struct KaizenAppApp: App {
    @State private var abaSelecionada = Aba.hoje
    @State private var rotinaParaAbrir: Int64?   // vem de um link kaizen://rotina/<id> (widget)
    @State private var mostrarSemana = false     // kaizen://semana (notificação do resumo semanal)
    @StateObject private var bloqueio = Bloqueio()
    // Boas-vindas só pra quem está começando (sem nenhuma rotina); quem já usa não vê
    @AppStorage("boasVindasVistas") private var boasVindasVistas = false
    @State private var mostrarBoasVindas = false
    @Environment(\.scenePhase) private var scenePhase

    enum Aba { case hoje, resumo, rotinas, ajustes }

    init() {
        NotificacaoDelegate.shared.registrar()
        // Na primeira abertura a permissão é pedida nas boas-vindas, no momento certo
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
            // Bloqueio com Face ID (ativado em Ajustes)
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
                    WidgetSync.atualizar()   // o widget pega o estado mais recente ao sair do app
                case .active: Task { await bloqueio.aoFicarAtivo() }
                default: break
                }
            }
            // Links: kaizen://rotinas abre a lista; kaizen://rotina/<id> abre a rotina;
            // kaizen://semana abre o resumo da semana
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
