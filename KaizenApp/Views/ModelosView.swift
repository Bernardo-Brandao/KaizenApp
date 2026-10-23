import SwiftUI

// Galeria de modelos de rotina, como os templates do Notion
struct ModelosView: View {
    @ObservedObject var viewModel: RotinaViewModel
    // Chamado com o id da rotina criada (pra quem abriu a galeria decidir o que fazer)
    var aoCriar: (Int64) -> Void = { _ in }

    private let colunas = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Comece com uma rotina pronta e ajuste do seu jeito.")
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: colunas, spacing: 12) {
                    ForEach(ModeloRotina.todos) { modelo in
                        NavigationLink {
                            ModeloDetalheView(modelo: modelo, viewModel: viewModel, aoCriar: aoCriar)
                        } label: {
                            CartaoModelo(modelo: modelo)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Modelos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CartaoModelo: View {
    let modelo: ModeloRotina

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(modelo.icone).font(.system(size: 34))
            Text(modelo.nome)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text("\(modelo.frequencia) · \(modelo.tarefas.count) tarefas")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
        .contentShape(Rectangle())
    }
}

// Prévia do modelo no formato da página da rotina, com o botão pra adicionar
struct ModeloDetalheView: View {
    let modelo: ModeloRotina
    @ObservedObject var viewModel: RotinaViewModel
    var aoCriar: (Int64) -> Void
    @State private var criado = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(modelo.icone).font(.system(size: 52))
                VStack(alignment: .leading, spacing: 4) {
                    Text(modelo.nome).font(.largeTitle.bold())
                    Text(modelo.descricao).foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Image(systemName: "repeat").frame(width: 20)
                    Text("Frequência").frame(width: 100, alignment: .leading)
                    Text(modelo.frequencia).foregroundStyle(.primary)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                ForEach(modelo.tarefas, id: \.nome) { tarefa in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: "square")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tarefa.nome)
                            if !tarefa.nota.isEmpty {
                                Text(tarefa.nota).font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Text("Você pode mudar o nome, as tarefas, a categoria e o lembrete depois.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                if let id = viewModel.criar(aPartirDe: modelo) {
                    criado = true
                    aoCriar(id)
                }
            } label: {
                Label(criado ? "Rotina adicionada" : "Adicionar rotina",
                      systemImage: criado ? "checkmark" : "plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(criado)
            .padding()
            .background(.bar)
        }
        .sensoryFeedback(.success, trigger: criado)
        .navigationBarTitleDisplayMode(.inline)
    }
}
