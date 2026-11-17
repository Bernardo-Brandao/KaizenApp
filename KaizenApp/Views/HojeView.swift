import SwiftUI

struct HojeView: View {
    @StateObject private var viewModel = HojeViewModel()
    @Binding var abaSelecionada: KaizenAppApp.Aba
    @Environment(\.scenePhase) private var scenePhase
    @State private var itemParaAnotar: ItemHoje?
    @State private var comemorando: Rotina?
    @State private var toques = 0
    @State private var conclusoes = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    cabecalho
                    if viewModel.doDia.isEmpty && viewModel.daSemana.isEmpty && viewModel.doMes.isEmpty && viewModel.puladas.isEmpty {
                        vazio
                    } else {
                        ForEach(ParteDoDia.allCases, id: \.self) { parte in
                            let itens = viewModel.doDia.filter { ParteDoDia(horario: $0.tarefa.horario) == parte }
                            if !itens.isEmpty {
                                secao(parte.titulo, itens: itens)
                            }
                        }
                        if !viewModel.daSemana.isEmpty {
                            secao("Esta semana", itens: viewModel.daSemana)
                        }
                        if !viewModel.doMes.isEmpty {
                            secao("Este mês", itens: viewModel.doMes)
                        }
                        if !viewModel.puladas.isEmpty {
                            puladas
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: Int64.self) { id in
                if let rotina = RotinaDAO().buscar(id: id) {
                    DetalheRotinaView(rotina: rotina)
                }
            }
            .overlay {
                if let rotina = comemorando {
                    ComemoracaoView(frequencia: rotina.frequencia)
                        .transition(.opacity)
                }
            }
            .sheet(item: $itemParaAnotar) { item in
                AnotarValorView(tarefa: item.tarefa, cor: cor(item)) { valor in
                    toques += 1
                    if viewModel.registrarValor(item, valor: valor) { comemorar(item.rotina) }
                }
                .presentationDetents([.medium])
            }
            .sensoryFeedback(.selection, trigger: toques)
            .sensoryFeedback(.success, trigger: conclusoes)
            .onAppear { viewModel.carregar() }
            .task { await sincronizarSaude() }
            .onChange(of: scenePhase) { _, fase in
                if fase == .active {
                    viewModel.carregar()
                    Task { await sincronizarSaude() }
                }
            }
        }
    }

    private var cabecalho: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dataDeHoje)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Hoje")
                    .font(.largeTitle.bold())
            }
            if !viewModel.doDia.isEmpty {
                let feitas = viewModel.feitasHoje, total = viewModel.doDia.count
                VStack(alignment: .leading, spacing: 8) {
                    Text(feitas == total ? "Tudo feito por hoje" : "\(feitas) de \(total) feitas")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(feitas == total ? Paleta.destaque : .secondary)
                    BarraProgresso(progresso: Double(feitas) / Double(total), altura: 4)
                }
            }
        }
        .padding(.top, 8)
    }

    private func secao(_ titulo: String, itens: [ItemHoje]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                ForEach(Array(itens.enumerated()), id: \.element.id) { indice, item in
                    LinhaHoje(item: item, cor: cor(item)) { tocar(item) }
                        .contextMenu {
                            NavigationLink(value: item.rotina.id ?? 0) {
                                Label("Abrir \(item.rotina.nome)", systemImage: "arrow.up.right")
                            }
                            Button { viewModel.alternarPulo(item.rotina) } label: {
                                Label(item.rotina.frequencia == "Diária" ? "Pular \(item.rotina.nome) hoje"
                                      : "Pular \(item.rotina.nome) neste período", systemImage: "forward")
                            }
                        }
                    if indice < itens.count - 1 {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
        }
    }

    private var puladas: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Puladas")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            ForEach(viewModel.puladas) { rotina in
                HStack {
                    Text("\(rotina.iconeExibido) \(rotina.nome)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Desfazer") { viewModel.alternarPulo(rotina) }
                        .font(.subheadline)
                        .tint(Paleta.destaque)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
            }
        }
    }

    private var vazio: some View {
        VStack(spacing: 12) {
            Text("Nada para hoje")
                .font(.headline)
            Text("Crie uma rotina e as tarefas do dia aparecem aqui, todas juntas.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Ver rotinas") { abaSelecionada = .rotinas }
                .buttonStyle(.bordered)
                .tint(Paleta.destaque)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func sincronizarSaude() async {
        let todas = viewModel.doDia + viewModel.daSemana + viewModel.doMes
        guard todas.contains(where: { !$0.tarefa.saude.isEmpty }) else { return }
        await SaudeService.sincronizar()
        viewModel.carregar()
    }

    private func tocar(_ item: ItemHoje) {
        if item.tarefa.ehContagem && !item.tarefa.concluidaHoje {
            toques += 1
            if viewModel.registrarValor(item, valor: item.tarefa.valorAtual + 1) { comemorar(item.rotina) }
            return
        }
        if item.tarefa.ehValor {
            itemParaAnotar = item
            return
        }
        toques += 1
        if viewModel.alternar(item) { comemorar(item.rotina) }
    }

    private func comemorar(_ rotina: Rotina) {
        conclusoes += 1
        withAnimation { comemorando = rotina }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { comemorando = nil }
        }
    }

    private func cor(_ item: ItemHoje) -> Color {
        Estilo.cor(categoriaHex: item.corHex, frequencia: item.rotina.frequencia)
    }

    private var dataDeHoje: String {
        let texto = Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "pt_BR")))
        return texto.prefix(1).uppercased() + texto.dropFirst()
    }
}

enum ParteDoDia: CaseIterable {
    case manha, tarde, noite, qualquerHora

    init(horario: String) {
        guard let hora = Int(horario.prefix(2)) else { self = .qualquerHora; return }
        self = hora < 12 ? .manha : hora < 18 ? .tarde : .noite
    }

    var titulo: String {
        switch self {
        case .manha: "Manhã"
        case .tarde: "Tarde"
        case .noite: "Noite"
        case .qualquerHora: "A qualquer hora"
        }
    }
}

struct LinhaHoje: View {
    let item: ItemHoje
    let cor: Color
    let aoTocar: () -> Void

    private var tarefa: Tarefa { item.tarefa }

    var body: some View {
        Button(action: aoTocar) {
            HStack(spacing: 14) {
                Group {
                    if tarefa.ehValor {
                        CirculoProgresso(progresso: tarefa.progressoValor, cor: cor)
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: tarefa.concluidaHoje ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(tarefa.concluidaHoje ? cor : .secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tarefa.nome)
                        .foregroundStyle(tarefa.concluidaHoje ? .secondary : .primary)
                        .strikethrough(tarefa.concluidaHoje && !tarefa.ehValor)
                    Text(detalhe)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if !tarefa.horario.isEmpty {
                    Text(tarefa.horario)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(tarefa.concluidaHoje ? .isSelected : [])
    }

    private var detalhe: String {
        var partes = ["\(item.rotina.iconeExibido) \(item.rotina.nome)"]
        if tarefa.ehValor { partes.append(tarefa.valorDescrito) }
        if !tarefa.nota.isEmpty { partes.append(tarefa.nota) }
        return partes.joined(separator: " · ")
    }
}
