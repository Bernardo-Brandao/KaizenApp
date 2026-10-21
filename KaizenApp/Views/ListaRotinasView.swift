import SwiftUI

struct ListaRotinasView: View {
    @StateObject var viewModel = RotinaViewModel()
    @StateObject private var categoriaViewModel = CategoriaViewModel()
    @State private var busca = ""
    @State private var filtroCategoriaId: Int64?   // nil = todas as categorias
    @State private var rotinaParaExcluir: Rotina?
    @State private var mostrarConfirmacaoExclusao = false
    @Environment(\.scenePhase) private var scenePhase

    var rotinasFiltradas: [Rotina] {
        viewModel.rotinas.filter { rotina in
            let passaBusca = busca.isEmpty || rotina.nome.localizedCaseInsensitiveContains(busca)
            let passaCategoria = filtroCategoriaId == nil || rotina.categoriaId == filtroCategoriaId
            return passaBusca && passaCategoria
        }
    }

    func categoria(de rotina: Rotina) -> Categoria? {
        categoriaViewModel.categorias.first { $0.id == rotina.categoriaId }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(rotinasFiltradas) { rotina in
                    NavigationLink(destination: DetalheRotinaView(rotina: rotina)) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(rotina.nome).font(.headline)
                                HStack(spacing: 6) {
                                    Text(rotina.frequencia).font(.subheadline).foregroundColor(.gray)
                                    if let categoria = categoria(de: rotina) {
                                        CategoriaTag(categoria: categoria)
                                    }
                                }
                            }
                            Spacer()
                            if let id = rotina.id, let progresso = viewModel.progresso[id], progresso.total > 0 {
                                ProgressoAnel(progresso: progresso)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            rotinaParaExcluir = rotina
                            mostrarConfirmacaoExclusao = true
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    }
                }
            }
            .searchable(text: $busca, prompt: "Buscar rotina")
            .navigationTitle("Minhas Rotinas")
            .overlay {
                if rotinasFiltradas.isEmpty && filtroCategoriaId != nil {
                    ContentUnavailableView("Nenhuma rotina nessa categoria",
                                           systemImage: "tag",
                                           description: Text("Escolha outra categoria no filtro."))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filtrar por categoria", selection: $filtroCategoriaId) {
                            Text("Todas").tag(Int64?.none)
                            ForEach(categoriaViewModel.categorias) { categoria in
                                Text(categoria.nome).tag(categoria.id)
                            }
                        }
                    } label: {
                        Image(systemName: filtroCategoriaId == nil
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                    .disabled(categoriaViewModel.categorias.isEmpty)
                }
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
            .onAppear {
                viewModel.carregar()
                categoriaViewModel.carregar()
                // Se a categoria do filtro foi excluída, volta a mostrar todas
                if let filtro = filtroCategoriaId,
                   !categoriaViewModel.categorias.contains(where: { $0.id == filtro }) {
                    filtroCategoriaId = nil
                }
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

    var body: some View {
        HStack(spacing: 6) {
            Text("\(progresso.concluidas)/\(progresso.total)")
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
            ZStack {
                Circle()
                    .stroke(AppTheme.primarySoft, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progresso.percentual)
                    .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if progresso.completo {
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                        .foregroundColor(AppTheme.primary)
                }
            }
            .frame(width: 26, height: 26)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(progresso.concluidas) de \(progresso.total) tarefas concluídas")
    }
}
