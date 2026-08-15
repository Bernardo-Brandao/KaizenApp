import SwiftUI

struct ListaRotinasView: View {
    @StateObject var viewModel = RotinaViewModel()
    @State private var busca = ""
    @State private var rotinaParaExcluir: Rotina?
    @State private var mostrarConfirmacaoExclusao = false

    var rotinasFiltradas: [Rotina] {
        busca.isEmpty ? viewModel.rotinas : viewModel.rotinas.filter {
            $0.nome.localizedCaseInsensitiveContains(busca)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(rotinasFiltradas) { rotina in
                    NavigationLink(destination: DetalheRotinaView(rotina: rotina)) {
                        VStack(alignment: .leading) {
                            Text(rotina.nome).font(.headline)
                            Text(rotina.frequencia).font(.subheadline).foregroundColor(.gray)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NovaRotinaView(viewModel: viewModel)) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear { viewModel.carregar() }
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
