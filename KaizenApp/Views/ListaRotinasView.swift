import SwiftUI

struct ListaRotinasView: View {
    @StateObject var viewModel = RotinaViewModel()
    @StateObject private var categoriaViewModel = CategoriaViewModel()
    @State private var busca = ""
    @State private var filtroCategoriaId: Int64?   // nil = todas as categorias
    @State private var rotinaParaExcluir: Rotina?
    @State private var mostrarConfirmacaoExclusao = false

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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rotina.nome).font(.headline)
                            HStack(spacing: 6) {
                                Text(rotina.frequencia).font(.subheadline).foregroundColor(.gray)
                                if let categoria = categoria(de: rotina) {
                                    CategoriaTag(categoria: categoria)
                                }
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
