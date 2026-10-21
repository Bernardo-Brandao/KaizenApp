import SwiftUI

struct CategoriasView: View {
    @StateObject var viewModel = CategoriaViewModel()
    @State private var novoNome = ""
    @State private var corSelecionada = "007AFF"

    let coresDisponiveis = ["007AFF", "34C759", "FF9500", "FF3B30", "AF52DE", "8E8E93"]

    var body: some View {
        NavigationStack {
            List {
                Section("Nova categoria") {
                    TextField("Nome da categoria", text: $novoNome)

                    HStack(spacing: 12) {
                        ForEach(coresDisponiveis, id: \.self) { cor in
                            Circle()
                                .fill(Color(hex: cor))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: corSelecionada == cor ? 2 : 0)
                                        .padding(-3)
                                )
                                .onTapGesture { corSelecionada = cor }
                        }
                    }
                    .padding(.vertical, 4)

                    Button("Adicionar categoria") {
                        guard !novoNome.isEmpty else { return }
                        viewModel.adicionar(nome: novoNome, corHex: corSelecionada)
                        novoNome = ""
                    }
                    .disabled(novoNome.isEmpty)
                }

                Section("Suas categorias") {
                    ForEach(viewModel.categorias) { categoria in
                        HStack {
                            Circle()
                                .fill(Color(hex: categoria.corHex))
                                .frame(width: 16, height: 16)
                            Text(categoria.nome)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { viewModel.excluir(viewModel.categorias[$0]) }
                    }
                }
            }
            .navigationTitle("Categorias")
            .onAppear { viewModel.carregar() }
        }
    }
}




