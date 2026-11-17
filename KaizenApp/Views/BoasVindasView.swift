import SwiftUI

struct BoasVindasView: View {
    let aoTerminar: (KaizenAppApp.Aba) -> Void

    @State private var pagina = 0
    @StateObject private var rotinaViewModel = RotinaViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $pagina) {
                    apresentacao.tag(0)
                    comoFunciona.tag(1)
                    lembretes.tag(2)
                    comecar.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 6) {
                    ForEach(0..<4) { indice in
                        Capsule()
                            .fill(indice == pagina ? Paleta.destaque : Paleta.trilha)
                            .frame(width: indice == pagina ? 18 : 6, height: 6)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: pagina)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                if pagina < 3 {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Pular") { aoTerminar(.hoje) }
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private var apresentacao: some View {
        pagina(botao: "Começar", acao: avancar) {
            Circle()
                .fill(Paleta.destaque)
                .frame(width: 64, height: 64)
                .padding(.bottom, 8)
            Text("Kaizen")
                .font(.largeTitle.bold())
            Text("Pequenas melhorias, todo dia.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var comoFunciona: some View {
        pagina(botao: "Continuar", acao: avancar) {
            Text("Como funciona")
                .font(.title.bold())
                .padding(.bottom, 12)
            VStack(alignment: .leading, spacing: 22) {
                item("sun.horizon", "Hoje", "Tudo o que tem pra fazer no dia, de todas as rotinas, numa lista só.")
                item("checklist", "Rotinas", "Agrupe tarefas. Marque como feito ou anote um valor, como 3 L de água.")
                item("flame", "Sequência", "Cada dia completo soma. Folgas e dias pulados não quebram a sequência.")
            }
        }
    }

    private var lembretes: some View {
        pagina(botao: "Permitir lembretes", acao: {
            NotificationManager.shared.solicitarPermissao()
            avancar()
        }, secundario: ("Agora não", avancar)) {
            Image(systemName: "bell")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Paleta.destaque)
                .padding(.bottom, 8)
            Text("Lembretes na hora certa")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Cada tarefa pode ter o seu horário. Se você já fez, o lembrete não toca.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var comecar: some View {
        pagina(botao: "Escolher um modelo", acao: {}, destinoDoBotao: true, secundario: ("Criar do zero", { aoTerminar(.rotinas) })) {
            Text("Primeira rotina")
                .font(.title.bold())
            Text("Comece com um modelo pronto, como Manhã ou Treino, e ajuste do seu jeito.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func pagina<Conteudo: View>(botao: String, acao: @escaping () -> Void, destinoDoBotao: Bool = false,
                                        secundario: (String, () -> Void)? = nil,
                                        @ViewBuilder conteudo: () -> Conteudo) -> some View {
        VStack(spacing: 12) {
            Spacer()
            conteudo()
            Spacer()
            Group {
                if destinoDoBotao {
                    NavigationLink {
                        ModelosView(viewModel: rotinaViewModel) { _ in aoTerminar(.hoje) }
                    } label: {
                        textoBotao(botao)
                    }
                } else {
                    Button(action: acao) { textoBotao(botao) }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Paleta.destaque)
            if let secundario {
                Button(secundario.0, action: secundario.1)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
    }

    private func textoBotao(_ texto: String) -> some View {
        Text(texto)
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }

    private func item(_ icone: String, _ titulo: String, _ texto: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icone)
                .font(.title2.weight(.light))
                .foregroundStyle(Paleta.destaque)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo).font(.headline)
                Text(texto)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func avancar() {
        withAnimation { pagina += 1 }
    }
}
