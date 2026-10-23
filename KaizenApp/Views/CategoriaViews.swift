import SwiftUI

struct CategoriasView: View {
    @StateObject var viewModel = CategoriaViewModel()
    @State private var novoNome = ""
    @State private var corSelecionada = "007AFF"

    let coresDisponiveis = ["007AFF", "34C759", "FF9500", "FF3B30", "AF52DE", "8E8E93"]

    var body: some View {
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

// Seção de formulário para escolher a categoria de uma rotina (usada em Nova e Editar)
struct CategoriaPickerSection: View {
    @Binding var categoriaId: Int64?
    @StateObject private var viewModel = CategoriaViewModel()

    var body: some View {
        Section("Categoria") {
            Picker("Categoria", selection: $categoriaId) {
                Text("Sem categoria").tag(Int64?.none)
                ForEach(viewModel.categorias) { categoria in
                    HStack {
                        Circle()
                            .fill(Color(hex: categoria.corHex))
                            .frame(width: 12, height: 12)
                        Text(categoria.nome)
                    }
                    .tag(categoria.id)
                }
            }
        }
        .onAppear { viewModel.carregar() }
    }
}

// Etiqueta colorida com o nome da categoria
struct CategoriaTag: View {
    let categoria: Categoria

    var body: some View {
        Text(categoria.nome)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(hex: categoria.corHex).opacity(0.18))
            .foregroundColor(Color(hex: categoria.corHex))
            .clipShape(Capsule())
    }
}




