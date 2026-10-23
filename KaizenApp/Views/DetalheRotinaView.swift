import SwiftUI

// Página da rotina, no estilo do Notion: capa na cor da rotina, emoji, título,
// propriedades em linhas e as tarefas como uma checklist
struct DetalheRotinaView: View {
    @State private var rotina: Rotina      // recarregada do banco ao aparecer, pra refletir edições
    @State private var categoria: Categoria?
    @State private var sequencia = 0
    @State private var recorde = 0
    @StateObject private var viewModel: TarefaViewModel
    @State private var novaTarefaNome = ""
    @State private var novaTarefaNota = ""
    @State private var novaTarefaDias: Set<Int> = []
    @State private var mostrarCampoNovaTarefa = false
    @FocusState private var focoNovaTarefa: Bool
    @State private var tarefaParaEditar: Tarefa?
    @State private var mostrarOrganizar = false
    @State private var mostrarEdicao = false
    @State private var mostrarEstatisticas = false
    @State private var mostrarComemoracao = false
    @State private var toquesEmTarefas = 0      // gatilho da vibração leve a cada toque
    @State private var conclusoes = 0           // gatilho da vibração de sucesso
    @Environment(\.scenePhase) private var scenePhase

    init(rotina: Rotina) {
        _rotina = State(initialValue: rotina)
        _viewModel = StateObject(wrappedValue: TarefaViewModel(rotinaId: rotina.id ?? 0, frequencia: rotina.frequencia))
    }

    private var cor: Color {
        Estilo.cor(categoriaHex: categoria?.corHex, frequencia: rotina.frequencia)
    }

    private var concluidas: Int {
        viewModel.tarefas.filter(\.concluidaHoje).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                capa
                VStack(alignment: .leading, spacing: 16) {
                    titulo
                    propriedades
                    if !rotina.ativa {
                        avisoPausada
                    } else if !viewModel.programadaHoje {
                        avisoFolga
                    }
                    Divider()
                    checklist
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea(edges: .top)
        .overlay {
            if mostrarComemoracao {
                ComemoracaoView(frequencia: rotina.frequencia)
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.selection, trigger: toquesEmTarefas)
        .sensoryFeedback(.success, trigger: conclusoes)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { mostrarEstatisticas = true } label: {
                    Image(systemName: "chart.bar.fill")
                }
                .accessibilityLabel("Estatísticas")
                Menu {
                    Button { mostrarEdicao = true } label: {
                        Label("Editar rotina", systemImage: "pencil")
                    }
                    if viewModel.todasTarefas.count > 1 {
                        Button { mostrarOrganizar = true } label: {
                            Label("Organizar tarefas", systemImage: "arrow.up.arrow.down")
                        }
                    }
                    Button { alternarPausa() } label: {
                        if rotina.ativa {
                            Label("Pausar rotina", systemImage: "pause.circle")
                        } else {
                            Label("Retomar rotina", systemImage: "play.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .navigationDestination(isPresented: $mostrarEstatisticas) {
            EstatisticasView(rotina: rotina)
        }
        .navigationDestination(isPresented: $mostrarEdicao) {
            EditarRotinaView(viewModel: RotinaViewModel(), rotina: rotina)
        }
        .sheet(item: $tarefaParaEditar) { tarefa in
            EditarTarefaView(tarefa: tarefa, mostrarDias: rotina.frequencia == "Diária", cor: cor) { nome, nota, dias in
                viewModel.editar(tarefa, nome: nome, nota: nota, dias: dias)
            }
            .presentationDetents([.medium])
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

    // MARK: - Cabeçalho

    private var capa: some View {
        Rectangle()
            .fill(cor.opacity(0.22))
            .frame(height: 150)
            .overlay(alignment: .bottomLeading) {
                Text(rotina.iconeExibido)
                    .font(.system(size: 52))
                    .padding(.leading, 20)
                    .offset(y: 28)
            }
    }

    private var titulo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rotina.nome)
                .font(.largeTitle.bold())
            if !rotina.descricao.isEmpty {
                Text(rotina.descricao)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 36)
    }

    // Propriedades em linhas, como numa página do Notion
    private var propriedades: some View {
        VStack(alignment: .leading, spacing: 10) {
            propriedade("Frequência", icone: "repeat") {
                Text(rotina.frequenciaDescrita)
            }
            propriedade("Categoria", icone: "tag") {
                if let categoria {
                    CategoriaTag(categoria: categoria)
                } else {
                    Text("Vazio").foregroundStyle(.tertiary)
                }
            }
            propriedade("Lembrete", icone: "bell") {
                Text(textoLembrete).foregroundStyle(rotina.lembreteAtivo ? .primary : .tertiary)
            }
            propriedade("Sequência", icone: "flame") {
                Text("\(sequencia) seguidas") + Text("  ·  recorde \(recorde)").foregroundColor(.secondary)
            }
            propriedade("Progresso", icone: "circle.dashed") {
                HStack(spacing: 8) {
                    ProgressView(value: viewModel.tarefas.isEmpty ? 0 : Double(concluidas) / Double(viewModel.tarefas.count))
                        .tint(cor)
                        .frame(width: 90)
                    Text("\(concluidas)/\(viewModel.tarefas.count)")
                        .font(.subheadline.monospacedDigit())
                }
            }
        }
        .font(.subheadline)
    }

    private func propriedade<Valor: View>(_ nome: String, icone: String, @ViewBuilder valor: () -> Valor) -> some View {
        HStack(alignment: .center, spacing: 0) {
            // Ícone com largura fixa pra os nomes ficarem alinhados, como numa tabela
            HStack(spacing: 8) {
                Image(systemName: icone).frame(width: 20)
                Text(nome)
            }
            .foregroundStyle(.secondary)
            .frame(width: 130, alignment: .leading)
            valor()
            Spacer(minLength: 0)
        }
    }

    private var textoLembrete: String {
        guard rotina.lembreteAtivo, !rotina.horarioLembrete.isEmpty else { return "Desligado" }
        let dias = ["domingo", "segunda", "terça", "quarta", "quinta", "sexta", "sábado"]
        switch rotina.frequencia {
        case "Semanal":
            let dia = dias[max(0, min(rotina.diaLembrete - 1, 6))]
            return "\(dia.capitalized) às \(rotina.horarioLembrete)"
        case "Mensal":
            return "Dia \(rotina.diaLembrete) às \(rotina.horarioLembrete)"
        default:
            return "Todo dia às \(rotina.horarioLembrete)"
        }
    }

    // MARK: - Checklist

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(viewModel.tarefas) { tarefa in
                LinhaTarefa(tarefa: tarefa, cor: cor, mostrarDias: rotina.frequencia == "Diária") {
                    toquesEmTarefas += 1
                    if viewModel.alternarConcluida(tarefa) {
                        comemorar()
                    }
                }
                .contextMenu { menuDaTarefa(tarefa) }
            }
            novaTarefa
            outrosDias
        }
    }

    @ViewBuilder
    private func menuDaTarefa(_ tarefa: Tarefa) -> some View {
        Button {
            tarefaParaEditar = tarefa
        } label: {
            Label("Editar", systemImage: "pencil")
        }
        Button(role: .destructive) {
            viewModel.excluir(tarefa)
        } label: {
            Label("Excluir tarefa", systemImage: "trash")
        }
    }

    // Tarefas que valem só em outros dias da semana (não aparecem na checklist de hoje)
    @ViewBuilder
    private var outrosDias: some View {
        let outras = viewModel.tarefasDeOutrosDias
        if !outras.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Em outros dias")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)
                ForEach(outras) { tarefa in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tarefa.nome).foregroundStyle(.secondary)
                            Text(DiasSemana.descricao(tarefa.diasSemana))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .contextMenu { menuDaTarefa(tarefa) }
                }
            }
        }
    }

    // "+ Nova tarefa" no fim da lista, que vira os campos de nome e nota
    @ViewBuilder
    private var novaTarefa: some View {
        if mostrarCampoNovaTarefa {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "square")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                    TextField("Nome da tarefa", text: $novaTarefaNome)
                        .focused($focoNovaTarefa)
                        .submitLabel(.done)
                        .onSubmit(adicionarTarefa)
                }
                TextField("Nota (opcional), ex.: 30 min", text: $novaTarefaNota)
                    .font(.subheadline)
                    .padding(.leading, 36)
                if rotina.frequencia == "Diária" {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dias da tarefa").font(.caption).foregroundStyle(.secondary)
                        SeletorDiasSemana(dias: $novaTarefaDias, cor: cor)
                    }
                    .padding(.leading, 36)
                }
                HStack {
                    Spacer()
                    Button("Cancelar") {
                        mostrarCampoNovaTarefa = false
                        novaTarefaNome = ""
                        novaTarefaNota = ""
                        novaTarefaDias = []
                    }
                    Button("Adicionar", action: adicionarTarefa)
                        .buttonStyle(.borderedProminent)
                        .tint(cor)
                        .disabled(novaTarefaNome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .font(.subheadline)
            }
            .padding(.vertical, 8)
        } else {
            Button {
                mostrarCampoNovaTarefa = true
                focoNovaTarefa = true
            } label: {
                Label(viewModel.tarefas.isEmpty ? "Adicione a primeira tarefa" : "Nova tarefa", systemImage: "plus")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func adicionarTarefa() {
        let nome = novaTarefaNome.trimmingCharacters(in: .whitespaces)
        guard !nome.isEmpty else { return }
        viewModel.adicionar(nome: nome, nota: novaTarefaNota, dias: novaTarefaDias)
        novaTarefaNome = ""
        novaTarefaNota = ""
        // Os dias ficam: ajuda a adicionar várias tarefas da sexta em sequência
        // Continua no campo, pra adicionar várias seguidas como numa lista do Notion
        focoNovaTarefa = true
        recarregarSequencia()
    }

    // MARK: - Ações

    // Mostra o selo de rotina completa por ~2s, com vibração de sucesso
    private func comemorar() {
        conclusoes += 1
        recarregarSequencia()
        withAnimation { mostrarComemoracao = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { mostrarComemoracao = false }
        }
    }

    private func alternarPausa() {
        RotinaViewModel().alternarPausa(rotina)
        recarregarRotina()
    }

    // Aviso de dia de folga de uma rotina com dias escolhidos
    private var avisoFolga: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.title2)
                .foregroundStyle(.indigo)
            VStack(alignment: .leading, spacing: 4) {
                Text("Hoje é folga")
                    .font(.subheadline.bold())
                Text("Esta rotina só vale em: \(DiasSemana.descricao(rotina.diasSemana)). Hoje ela não conta e não quebra a sequência.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.indigo.opacity(0.12)))
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
                Text("Sem lembretes, e os períodos pausados não quebram a sua sequência.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Retomar", action: alternarPausa)
                .buttonStyle(.borderedProminent)
                .tint(cor)
                .controlSize(.small)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange.opacity(0.12)))
    }

    // Busca a versão salva da rotina (pode ter sido editada), a categoria e a sequência
    private func recarregarRotina() {
        if let id = rotina.id, let salva = RotinaDAO().buscar(id: id) {
            rotina = salva
        }
        viewModel.frequencia = rotina.frequencia
        viewModel.programadaHoje = rotina.programada(em: DataUtil.hoje())
        categoria = CategoriaDAO().listarTodas().first { $0.id == rotina.categoriaId }
        recarregarSequencia()
    }

    private func recarregarSequencia() {
        guard let id = rotina.id else { return }
        let estatisticas = EstatisticasViewModel(rotinaId: id, frequencia: rotina.frequencia, diasSemana: rotina.diasSemana)
        estatisticas.carregar()
        sequencia = estatisticas.streakAtual
        recorde = estatisticas.recorde
    }
}

// MARK: - Linha da checklist

struct LinhaTarefa: View {
    let tarefa: Tarefa
    let cor: Color
    var mostrarDias = false
    let aoTocar: () -> Void

    var body: some View {
        Button(action: aoTocar) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: tarefa.concluidaHoje ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(tarefa.concluidaHoje ? cor : .secondary)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 2) {
                    Text(tarefa.nome)
                        .foregroundStyle(tarefa.concluidaHoje ? .secondary : .primary)
                        .strikethrough(tarefa.concluidaHoje)
                        .multilineTextAlignment(.leading)
                    if !tarefa.nota.isEmpty {
                        Text(tarefa.nota)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
                // Tarefa só de alguns dias: etiqueta com os dias
                if mostrarDias && !tarefa.diasSemana.isEmpty {
                    Text(DiasSemana.descricao(tarefa.diasSemana))
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(cor.opacity(0.15), in: Capsule())
                        .foregroundStyle(cor)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(tarefa.concluidaHoje ? .isSelected : [])
    }
}

// MARK: - Organizar tarefas (arrastar pra reordenar, deslizar pra excluir)
struct OrganizarTarefasView: View {
    @ObservedObject var viewModel: TarefaViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.todasTarefas) { tarefa in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tarefa.nome)
                        if !tarefa.nota.isEmpty {
                            Text(tarefa.nota)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onMove { origem, destino in
                    viewModel.mover(de: origem, para: destino)
                }
                .onDelete { indices in
                    indices.map { viewModel.todasTarefas[$0] }.forEach(viewModel.excluir)
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
