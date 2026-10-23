import SwiftUI

struct ListaRotinasView: View {
    @StateObject var viewModel = RotinaViewModel()
    @Binding var rotinaParaAbrir: Int64?            // pedido vindo de um link do widget
    @State private var rotinaAberta: Rotina?
    @StateObject private var categoriaViewModel = CategoriaViewModel()
    @State private var busca = ""
    @State private var rotinaParaExcluir: Rotina?
    @State private var mostrarConfirmacaoExclusao = false
    @Environment(\.scenePhase) private var scenePhase

    var rotinasFiltradas: [Rotina] {
        viewModel.rotinas.filter { busca.isEmpty || $0.nome.localizedCaseInsensitiveContains(busca) }
    }

    // Rotinas ativas agrupadas por categoria (na ordem das categorias), com "Sem categoria" no fim
    private var grupos: [(categoria: Categoria?, rotinas: [Rotina])] {
        let ativas = rotinasFiltradas.filter(\.ativa)
        var resultado: [(categoria: Categoria?, rotinas: [Rotina])] = categoriaViewModel.categorias.compactMap { categoria in
            let doGrupo = ativas.filter { $0.categoriaId == categoria.id }
            return doGrupo.isEmpty ? nil : (categoria, doGrupo)
        }
        let semCategoria = ativas.filter { rotina in
            !categoriaViewModel.categorias.contains { $0.id == rotina.categoriaId }
        }
        if !semCategoria.isEmpty {
            resultado.append((nil, semCategoria))
        }
        return resultado
    }

    func categoria(de rotina: Rotina) -> Categoria? {
        categoriaViewModel.categorias.first { $0.id == rotina.categoriaId }
    }

    // Linha de uma rotina: nome, frequência, categoria e progresso (ou "Pausada").
    // Deslizar pra direita pausa/retoma; pra esquerda exclui.
    @ViewBuilder
    private func linha(_ rotina: Rotina) -> some View {
        NavigationLink(destination: DetalheRotinaView(rotina: rotina)) {
            HStack(spacing: 12) {
                IconeRotina(icone: rotina.iconeExibido)
                VStack(alignment: .leading, spacing: 2) {
                    Text(rotina.nome).font(.body.weight(.medium))
                    Text(rotina.frequencia).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if !rotina.ativa {
                    Label("Pausada", systemImage: "pause.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let id = rotina.id, let progresso = viewModel.progresso[id], progresso.total > 0 {
                    ProgressoAnel(progresso: progresso,
                                  cor: Estilo.cor(categoriaHex: categoria(de: rotina)?.corHex, frequencia: rotina.frequencia))
                }
            }
            .opacity(rotina.ativa ? 1 : 0.6)
        }
        .swipeActions(edge: .leading) {
            Button {
                viewModel.alternarPausa(rotina)
            } label: {
                if rotina.ativa {
                    Label("Pausar", systemImage: "pause.fill")
                } else {
                    Label("Retomar", systemImage: "play.fill")
                }
            }
            .tint(rotina.ativa ? .orange : AppTheme.primary)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                rotinaParaExcluir = rotina
                mostrarConfirmacaoExclusao = true
            } label: {
                Label("Excluir", systemImage: "trash")
            }
        }
    }

    // Abre a rotina pedida pelo link e limpa o pedido
    private func abrirRotinaPedida() {
        guard let id = rotinaParaAbrir else { return }
        rotinaParaAbrir = nil
        rotinaAberta = RotinaDAO().buscar(id: id)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grupos, id: \.categoria?.id) { grupo in
                    Section {
                        ForEach(grupo.rotinas) { rotina in
                            linha(rotina)
                        }
                    } header: {
                        if let categoria = grupo.categoria {
                            HStack(spacing: 6) {
                                Circle().fill(Color(hex: categoria.corHex)).frame(width: 8, height: 8)
                                Text(categoria.nome)
                            }
                        } else if !categoriaViewModel.categorias.isEmpty {
                            Text("Sem categoria")
                        }
                    }
                }
                let pausadas = rotinasFiltradas.filter { !$0.ativa }
                if !pausadas.isEmpty {
                    Section("Pausadas") {
                        ForEach(pausadas) { rotina in
                            linha(rotina)
                        }
                    }
                }
            }
            .searchable(text: $busca, prompt: "Buscar rotina")
            .navigationTitle("Rotinas")
            .overlay {
                if viewModel.rotinas.isEmpty {
                    ContentUnavailableView {
                        Label("Crie sua primeira rotina", systemImage: "checklist")
                    } description: {
                        Text("Uma rotina junta as tarefas que você quer repetir todo dia, semana ou mês.")
                    } actions: {
                        NavigationLink("Criar rotina") { NovaRotinaView(viewModel: viewModel) }
                            .buttonStyle(.borderedProminent)
                    }
                } else if rotinasFiltradas.isEmpty {
                    ContentUnavailableView.search(text: busca)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NovaRotinaView(viewModel: viewModel)) {
                        Image(systemName: "plus")
                    }
                }
            }
            // Recarrega ao voltar pro app — se começou um período novo, o progresso zera
            .onChange(of: scenePhase) { _, fase in
                if fase == .active { viewModel.carregar() }
            }
            .navigationDestination(item: $rotinaAberta) { rotina in
                DetalheRotinaView(rotina: rotina)
            }
            .onChange(of: rotinaParaAbrir) { abrirRotinaPedida() }
            .onAppear {
                abrirRotinaPedida()
                viewModel.carregar()
                categoriaViewModel.carregar()
            }
            .confirmationDialog(
                "Excluir rotina?",
                isPresented: $mostrarConfirmacaoExclusao,
                presenting: rotinaParaExcluir
            ) { rotina in
                Button("Excluir", role: .destructive) {
                    viewModel.excluir(rotina)
                }
                Button("Cancelar", role: .cancel) {}
            } message: { rotina in
                Text("Tem certeza que deseja excluir \"\(rotina.nome)\"? Essa ação não pode ser desfeita.")
            }
        }
    }
}

// Anel com o progresso do período atual e o "3/5" ao lado; vira um check quando completo
struct ProgressoAnel: View {
    let progresso: ProgressoRotina
    var cor: Color = AppTheme.primary

    var body: some View {
        HStack(spacing: 6) {
            Text("\(progresso.concluidas)/\(progresso.total)")
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
            ZStack {
                Circle()
                    .stroke(cor.opacity(0.18), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progresso.percentual)
                    .stroke(cor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if progresso.completo {
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                        .foregroundColor(cor)
                }
            }
            .frame(width: 26, height: 26)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(progresso.concluidas) de \(progresso.total) tarefas concluídas")
    }
}
