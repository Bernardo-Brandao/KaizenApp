import SwiftUI

struct DetalheRotinaView: View {
    @State private var rotina: Rotina      // recarregada do banco ao aparecer, pra refletir edições
    @State private var categoria: Categoria?
    @StateObject private var viewModel: TarefaViewModel
    @State private var novaTarefaNome = ""
    @State private var mostrarCampoNovaTarefa = false
    @State private var tarefaParaRenomear: Tarefa?
    @State private var nomeEditado = ""
    @State private var mostrarOrganizar = false
    @Environment(\.scenePhase) private var scenePhase

    init(rotina: Rotina) {
        _rotina = State(initialValue: rotina)
        _viewModel = StateObject(wrappedValue: TarefaViewModel(rotinaId: rotina.id ?? 0, frequencia: rotina.frequencia))
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
                    HStack(spacing: 8) {
                        Text(rotina.frequencia)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let categoria {
                            CategoriaTag(categoria: categoria)
                        }
                    }

                    ProgressView(value: progresso)
                        .tint(AppTheme.primary)
                        .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if !rotina.ativa {
                    avisoPausada
                }

                // Grid de tarefas
                if viewModel.tarefas.count > 1 {
                    HStack {
                        Text("Tarefas")
                            .font(.headline)
                        Spacer()
                        Button("Organizar") { mostrarOrganizar = true }
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                }

                LazyVGrid(columns: colunas, spacing: 14) {
                    ForEach(viewModel.tarefas) { tarefa in
                        TarefaCard(tarefa: tarefa) {
                            viewModel.alternarConcluida(tarefa)
                        }
                        .contextMenu {
                            Button {
                                nomeEditado = tarefa.nome
                                tarefaParaRenomear = tarefa
                            } label: {
                                Label("Renomear", systemImage: "pencil")
                            }
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
                    NavigationLink(destination: EstatisticasView(rotina: rotina)) {
                        Image(systemName: "chart.bar.fill")
                    }
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
        .alert("Renomear tarefa", isPresented: Binding(
            get: { tarefaParaRenomear != nil },
            set: { if !$0 { tarefaParaRenomear = nil } }
        )) {
            TextField("Nome da tarefa", text: $nomeEditado)
            Button("Salvar") {
                if let tarefa = tarefaParaRenomear {
                    viewModel.renomear(tarefa, para: nomeEditado)
                }
            }
            Button("Cancelar", role: .cancel) {}
        }
        .sheet(isPresented: $mostrarOrganizar) {
            OrganizarTarefasView(viewModel: viewModel)
        }
        .onAppear {
            recarregarRotina()
            viewModel.carregar()
        }
        // Recarrega ao voltar pro app — se virou o dia, as tarefas aparecem desmarcadas
        .onChange(of: scenePhase) { _, fase in
            if fase == .active { viewModel.carregar() }
        }
    }

    // Aviso de rotina pausada, com botão pra retomar
    private var avisoPausada: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "pause.circle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Rotina pausada")
                    .font(.subheadline.bold())
                Text("Sem lembretes, e os períodos pausados não quebram o seu streak.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Retomar") {
                RotinaViewModel().alternarPausa(rotina)
                recarregarRotina()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
            .controlSize(.small)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange.opacity(0.12)))
        .padding(.horizontal)
    }

    // Busca a versão salva da rotina (pode ter sido editada) e a categoria dela
    private func recarregarRotina() {
        if let id = rotina.id, let salva = RotinaDAO().buscar(id: id) {
            rotina = salva
        }
        viewModel.frequencia = rotina.frequencia
        categoria = CategoriaDAO().listarTodas().first { $0.id == rotina.categoriaId }
    }
}

// MARK: - Organizar tarefas (arrastar pra reordenar, deslizar pra excluir)
struct OrganizarTarefasView: View {
    @ObservedObject var viewModel: TarefaViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tarefas) { tarefa in
                    Text(tarefa.nome)
                }
                .onMove { origem, destino in
                    viewModel.mover(de: origem, para: destino)
                }
                .onDelete { indices in
                    indices.map { viewModel.tarefas[$0] }.forEach(viewModel.excluir)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Organizar tarefas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
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
                        .foregroundColor(tarefa.concluidaHoje ? AppTheme.primary : .secondary)
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
                    .fill(tarefa.concluidaHoje ? AppTheme.primarySoft : AppTheme.cardBackground)
            )
            
        }
        .buttonStyle(.plain)
    }
}
