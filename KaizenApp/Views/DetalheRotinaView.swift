import SwiftUI

struct DetalheRotinaView: View {
    let rotina: Rotina
    @StateObject private var viewModel: TarefaViewModel
    @State private var novaTarefaNome = ""
    @State private var mostrarCampoNovaTarefa = false

    init(rotina: Rotina) {
        self.rotina = rotina
        _viewModel = StateObject(wrappedValue: TarefaViewModel(rotinaId: rotina.id ?? 0))
    }

    let colunas = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var progresso: Double {
        guard !viewModel.tarefas.isEmpty else { return 0 }
        let concluidas = viewModel.tarefas.filter { $0.concluidaHoje }.count
        return Double(concluidas) / Double(viewModel.tarefas.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Cabeçalho
                VStack(alignment: .leading, spacing: 6) {
                    Text(rotina.nome)
                        .font(.largeTitle.bold())
                    Text(rotina.frequencia)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ProgressView(value: progresso)
                        .tint(.primary)
                        .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Grid de tarefas
                LazyVGrid(columns: colunas, spacing: 14) {
                    ForEach(viewModel.tarefas) { tarefa in
                        TarefaCard(tarefa: tarefa) {
                            viewModel.alternarConcluida(tarefa)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.excluir(tarefa)
                            } label: {
                                Label("Excluir tarefa", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)

                if viewModel.tarefas.isEmpty {
                    Text("Nenhuma tarefa ainda. Toque em + pra adicionar.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }

                if mostrarCampoNovaTarefa {
                    HStack {
                        TextField("Nome da tarefa", text: $novaTarefaNome)
                            .textFieldStyle(.roundedBorder)
                        Button("Adicionar") {
                            guard !novaTarefaNome.isEmpty else { return }
                            viewModel.adicionar(nome: novaTarefaNome)
                            novaTarefaNome = ""
                            mostrarCampoNovaTarefa = false
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Detalhes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    NavigationLink(destination: EditarRotinaView(viewModel: RotinaViewModel(), rotina: rotina)) {
                        Image(systemName: "pencil")
                    }
                    Button {
                        mostrarCampoNovaTarefa.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear { viewModel.carregar() }
    }
}

// MARK: - Card de tarefa (Checkbox + ImageView minimalista)
struct TarefaCard: View {
    let tarefa: Tarefa
    let aoTocar: () -> Void

    var body: some View {
        Button(action: aoTocar) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: tarefa.concluidaHoje ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(tarefa.concluidaHoje ? .green : .secondary)
                    Spacer()
                }
                Text(tarefa.nome)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(tarefa.concluidaHoje ? .secondary : .primary)
                    .strikethrough(tarefa.concluidaHoje)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}
