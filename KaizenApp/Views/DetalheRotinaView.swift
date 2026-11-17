import SwiftUI

struct DetalheRotinaView: View {
    @State private var rotina: Rotina
    @State private var categoria: Categoria?
    @State private var sequencia = 0
    @State private var recorde = 0
    @StateObject private var viewModel: TarefaViewModel
    @State private var novaTarefaNome = ""
    @State private var novaTarefaNota = ""
    @State private var novaTarefaDias: Set<Int> = []
    @State private var novaTarefaHorario = ""
    @State private var novaTarefaTipo = "check"
    @State private var novaTarefaUnidade = ""
    @State private var novaTarefaMeta = ""
    @State private var novaTarefaSaude = ""
    @State private var mostrarCampoNovaTarefa = false
    @FocusState private var focoNovaTarefa: Bool
    @State private var tarefaParaEditar: Tarefa?
    @State private var tarefaParaAnotar: Tarefa?
    @State private var mostrarOrganizar = false
    @State private var mostrarEdicao = false
    @State private var mostrarEstatisticas = false
    @State private var mostrarComemoracao = false
    @State private var mostrarDiasAnteriores = false
    @State private var pulada = false
    @State private var toquesEmTarefas = 0
    @State private var conclusoes = 0
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
                    } else if pulada {
                        avisoPulada
                    } else if !rotina.programada(em: DataUtil.hoje()) {
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
                    if rotina.ativa && rotina.programada(em: DataUtil.hoje()) {
                        Button { alternarPulo() } label: {
                            if pulada {
                                Label("Desfazer pulo", systemImage: "arrow.uturn.backward")
                            } else {
                                Label(textoPular, systemImage: "forward")
                            }
                        }
                    }
                    Button { mostrarDiasAnteriores = true } label: {
                        Label("Corrigir dias anteriores", systemImage: "calendar.badge.checkmark")
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
        .sheet(item: $tarefaParaAnotar) { tarefa in
            AnotarValorView(tarefa: tarefa, cor: cor) { valor in
                toquesEmTarefas += 1
                if viewModel.registrarValor(tarefa, valor: valor) {
                    comemorar()
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $tarefaParaEditar) { tarefa in
            EditarTarefaView(tarefa: tarefa, mostrarDias: rotina.frequencia == "Diária", frequencia: rotina.frequencia, cor: cor) {
                nome, nota, dias, horario, tipo, unidade, meta, saude in
                viewModel.editar(tarefa, nome: nome, nota: nota, dias: dias, horario: horario,
                                 tipo: tipo, unidade: unidade, meta: meta, saude: saude)
                Task { await sincronizarSaude() }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $mostrarDiasAnteriores) {
            DiasAnterioresView(rotina: rotina, cor: cor) { recarregarSequencia() }
        }
        .sheet(isPresented: $mostrarOrganizar) {
            OrganizarTarefasView(viewModel: viewModel)
        }
        .onAppear {
            recarregarRotina()
            viewModel.carregar()
        }
        .task { await sincronizarSaude() }
        .onChange(of: scenePhase) { _, fase in
            if fase == .active {
                viewModel.carregar()
                Task { await sincronizarSaude() }
            }
        }
    }

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
            propriedade("Lembretes", icone: "bell") {
                Text(textoLembrete).foregroundStyle(horariosDasTarefas.isEmpty ? .tertiary : .primary)
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

    private var horariosDasTarefas: [String] {
        Set(viewModel.todasTarefas.map(\.horario).filter { !$0.isEmpty }).sorted()
    }

    private var textoLembrete: String {
        let horarios = horariosDasTarefas
        guard !horarios.isEmpty else { return "Nenhum — defina na tarefa" }
        let lista = horarios.count > 3 ? "\(horarios.count) horários"
            : horarios.count == 1 ? horarios[0]
            : horarios.dropLast().joined(separator: ", ") + " e " + horarios[horarios.count - 1]
        let dias = ["domingo", "segunda", "terça", "quarta", "quinta", "sexta", "sábado"]
        switch rotina.frequencia {
        case "Semanal": return "\(dias[max(0, min(rotina.diaLembrete - 1, 6))].capitalized) · \(lista)"
        case "Mensal": return "Dia \(rotina.diaLembrete) · \(lista)"
        default: return lista
        }
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(viewModel.tarefas) { tarefa in
                LinhaTarefa(tarefa: tarefa, cor: cor, mostrarDias: rotina.frequencia == "Diária") {
                    if tarefa.ehContagem && !tarefa.concluidaHoje {
                        toquesEmTarefas += 1
                        if viewModel.registrarValor(tarefa, valor: tarefa.valorAtual + 1) { comemorar() }
                        return
                    }
                    if tarefa.ehValor {
                        tarefaParaAnotar = tarefa
                        return
                    }
                    toquesEmTarefas += 1
                    if viewModel.alternarConcluida(tarefa) {
                        comemorar()
                    }
                }
                .contextMenu { menuDaTarefa(tarefa) }
            }
            novaTarefa
            outrosDias
            Button { mostrarDiasAnteriores = true } label: {
                Label("Dias anteriores", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func menuDaTarefa(_ tarefa: Tarefa) -> some View {
        if tarefa.ehContagem {
            Button {
                tarefaParaAnotar = tarefa
            } label: {
                Label("Ajustar contagem", systemImage: "plusminus")
            }
        }
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
                            Text(tarefa.horario.isEmpty ? DiasSemana.descricao(tarefa.diasSemana)
                                 : "\(DiasSemana.descricao(tarefa.diasSemana)) · \(tarefa.horario)")
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
                VStack(spacing: 6) {
                    CampoTipoTarefa(tipo: $novaTarefaTipo, unidade: $novaTarefaUnidade, meta: $novaTarefaMeta, saude: $novaTarefaSaude,
                                    frequencia: rotina.frequencia)
                        .textFieldStyle(.roundedBorder)
                    CampoHorario(horario: $novaTarefaHorario)
                }
                .font(.subheadline)
                .padding(.leading, 36)
                HStack {
                    Spacer()
                    Button("Cancelar") {
                        mostrarCampoNovaTarefa = false
                        novaTarefaNome = ""
                        novaTarefaNota = ""
                        novaTarefaDias = []
                        novaTarefaHorario = ""
                        novaTarefaTipo = "check"
                        novaTarefaUnidade = ""
                        novaTarefaMeta = ""
                        novaTarefaSaude = ""
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
        viewModel.adicionar(nome: nome, nota: novaTarefaNota, dias: novaTarefaDias, horario: novaTarefaHorario,
                            tipo: novaTarefaTipo, unidade: novaTarefaUnidade, meta: NumeroUtil.ler(novaTarefaMeta),
                            saude: novaTarefaSaude)
        let ligadaAoSaude = !novaTarefaSaude.isEmpty
        novaTarefaNome = ""
        novaTarefaNota = ""
        novaTarefaHorario = ""
        novaTarefaTipo = "check"
        novaTarefaUnidade = ""
        novaTarefaMeta = ""
        novaTarefaSaude = ""
        if ligadaAoSaude { Task { await sincronizarSaude() } }
        focoNovaTarefa = true
        recarregarSequencia()
    }

    private func sincronizarSaude() async {
        guard viewModel.todasTarefas.contains(where: { !$0.saude.isEmpty }) else { return }
        await SaudeService.sincronizar()
        viewModel.carregar()
        recarregarSequencia()
    }

    private func comemorar() {
        conclusoes += 1
        recarregarSequencia()
        withAnimation { mostrarComemoracao = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { mostrarComemoracao = false }
        }
    }

    private var textoPular: String {
        switch rotina.frequencia {
        case "Semanal": "Pular esta semana"
        case "Mensal": "Pular este mês"
        default: "Pular hoje"
        }
    }

    private func alternarPulo() {
        guard let id = rotina.id else { return }
        let periodo = DataUtil.periodoAtual(frequencia: rotina.frequencia)
        if pulada {
            PuloDAO().desfazer(rotinaId: id, periodo: periodo)
        } else {
            PuloDAO().pular(rotinaId: id, periodo: periodo)
        }
        recarregarRotina()
        viewModel.carregar()
        NotificationManager.shared.atualizarLembrete(rotinaId: id)
        WidgetSync.atualizar()
    }

    private var avisoPulada: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "forward.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(rotina.frequencia == "Diária" ? "Pulada hoje" : rotina.frequencia == "Semanal" ? "Pulada nesta semana" : "Pulada neste mês")
                    .font(.subheadline.bold())
                Text("Não conta e não quebra a sequência. Os lembretes não tocam.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button("Desfazer", action: alternarPulo)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.tertiarySystemFill)))
    }

    private func alternarPausa() {
        RotinaViewModel().alternarPausa(rotina)
        recarregarRotina()
    }

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

    private func recarregarRotina() {
        if let id = rotina.id, let salva = RotinaDAO().buscar(id: id) {
            rotina = salva
        }
        pulada = PuloDAO().puladaAgora(rotina)
        viewModel.frequencia = rotina.frequencia
        viewModel.programadaHoje = rotina.programada(em: DataUtil.hoje()) && !pulada
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

struct LinhaTarefa: View {
    let tarefa: Tarefa
    let cor: Color
    var mostrarDias = false
    let aoTocar: () -> Void

    var body: some View {
        Button(action: aoTocar) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if tarefa.ehValor {
                    CirculoProgresso(progresso: tarefa.progressoValor, cor: cor)
                        .frame(width: 22, height: 22)
                        .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 6 }
                } else {
                    Image(systemName: tarefa.concluidaHoje ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(tarefa.concluidaHoje ? cor : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(tarefa.nome)
                        .foregroundStyle(tarefa.concluidaHoje ? .secondary : .primary)
                        .strikethrough(tarefa.concluidaHoje && !tarefa.ehValor)
                        .multilineTextAlignment(.leading)
                    if tarefa.ehValor {
                        (tarefa.saude.isEmpty ? Text("") : Text(Image(systemName: "heart.fill")) + Text(" "))
                            .font(.caption2)
                            .foregroundStyle(.pink)
                        + Text(tarefa.valorDescrito)
                            .font(.subheadline.weight(.medium).monospacedDigit())
                            .foregroundStyle(tarefa.concluidaHoje ? cor : .secondary)
                    }
                    if !tarefa.nota.isEmpty {
                        Text(tarefa.nota)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
                if !tarefa.horario.isEmpty {
                    EtiquetaHorario(horario: tarefa.horario)
                }
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
