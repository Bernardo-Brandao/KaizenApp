import SwiftUI

// Aba inicial, no estilo do app Fitness: três anéis (hoje, semana, mês), a semana em mini-anéis,
// as rotinas do período e os cartões de sequência e prêmios
struct ResumoView: View {
    @StateObject private var viewModel = ResumoViewModel()
    @Binding var abaSelecionada: KaizenAppApp.Aba
    @Binding var mostrarSemana: Bool                 // também aberto pela notificação de domingo
    @Environment(\.scenePhase) private var scenePhase
    @State private var mostrarModelos = false
    @StateObject private var rotinaViewModel = RotinaViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    cabecalho
                    aneis
                    semana
                    rotinasDoPeriodo
                    cartoes
                    cartaoSemana
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
            .navigationDestination(isPresented: $mostrarSemana) {
                ResumoSemanalView()
            }
            .navigationDestination(isPresented: $mostrarModelos) {
                ModelosView(viewModel: rotinaViewModel) { _ in
                    mostrarModelos = false
                    viewModel.carregar()
                }
            }
            .onAppear { viewModel.carregar() }
            .onChange(of: scenePhase) { _, fase in
                if fase == .active { viewModel.carregar() }
            }
        }
    }

    // MARK: - Seções

    private var cabecalho: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(dataDeHoje)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Resumo")
                .font(.largeTitle.bold())
        }
        .padding(.top, 8)
    }

    private var aneis: some View {
        HStack(spacing: 24) {
            AneisAtividade(hoje: viewModel.fracao("Diária"),
                           semana: viewModel.fracao("Semanal"),
                           mes: viewModel.fracao("Mensal"),
                           tamanho: 150)
            VStack(alignment: .leading, spacing: 10) {
                legendaAnel("Hoje", frequencia: "Diária", cor: Estilo.corHoje)
                legendaAnel("Semana", frequencia: "Semanal", cor: Estilo.corSemana)
                legendaAnel("Mês", frequencia: "Mensal", cor: Estilo.corMes)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
    }

    private func legendaAnel(_ titulo: String, frequencia: String, cor: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titulo)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(cor)
            if let p = ResumoViewModel.progresso(viewModel.rotinas, frequencia: frequencia) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(p.feitas)/\(p.total)").font(Estilo.numero(22))
                    Text("tarefas").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("—").font(Estilo.numero(22)).foregroundStyle(.tertiary)
            }
        }
    }

    private var semana: some View {
        HStack {
            ForEach(viewModel.semana) { dia in
                VStack(spacing: 6) {
                    Text(inicialDoDia(dia.data))
                        .font(.caption2.weight(dia.ehHoje ? .bold : .regular))
                        .foregroundStyle(dia.ehHoje ? .primary : .secondary)
                    AnelProgresso(progresso: dia.futuro ? 0 : (dia.progresso ?? 0),
                                  cor: Estilo.corHoje, espessura: 4)
                        .frame(width: 30, height: 30)
                        .opacity(dia.futuro ? 0.35 : 1)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(dia.futuro ? "\(dia.data): ainda não chegou"
                                    : "\(dia.data): \(Int((dia.progresso ?? 0) * 100))%")
            }
        }
    }

    @ViewBuilder
    private var rotinasDoPeriodo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suas rotinas")
                .font(.title3.bold())
            if viewModel.rotinas.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comece com uma rotina pronta e ajuste do seu jeito.")
                        .foregroundStyle(.secondary)
                    // Três modelos de atalho, e o resto na galeria
                    HStack(spacing: 10) {
                        ForEach(ModeloRotina.todos.prefix(3)) { modelo in
                            NavigationLink {
                                ModeloDetalheView(modelo: modelo, viewModel: rotinaViewModel) { _ in
                                    viewModel.carregar()
                                }
                            } label: {
                                CartaoModelo(modelo: modelo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack {
                        Button("Ver todos os modelos") { mostrarModelos = true }
                        Spacer()
                        Button("Criar do zero") { abaSelecionada = .rotinas }
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.rotinas.enumerated()), id: \.element.id) { indice, rotina in
                        NavigationLink(value: rotina.id) {
                            linhaRotina(rotina)
                        }
                        .buttonStyle(.plain)
                        if indice < viewModel.rotinas.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
            }
        }
    }

    private func linhaRotina(_ rotina: ResumoRotina) -> some View {
        let feitas = rotina.concluidas(em: .now)
        let cor = Estilo.cor(categoriaHex: rotina.corHex, frequencia: rotina.frequencia)
        return HStack(spacing: 12) {
            IconeRotina(icone: rotina.icone.isEmpty ? Rotina.iconePadrao : rotina.icone)
            VStack(alignment: .leading, spacing: 2) {
                Text(rotina.nome).font(.body.weight(.medium))
                Text(rotina.total == 0 ? "Sem tarefas" : "\(feitas) de \(rotina.total) · \(rotina.frequencia)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if rotina.completa(em: .now) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(cor)
            } else if rotina.total > 0 {
                AnelProgresso(progresso: Double(feitas) / Double(rotina.total), cor: cor, espessura: 4)
                    .frame(width: 28, height: 28)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var cartoes: some View {
        HStack(spacing: 12) {
            cartao(titulo: "Sequência", icone: "flame.fill", cor: .orange,
                   valor: "\(viewModel.melhorSequenciaAtual)",
                   unidade: viewModel.melhorSequenciaAtual == 1 ? "seguida" : "seguidas")
            Button { abaSelecionada = .premios } label: {
                cartao(titulo: "Prêmios", icone: "trophy.fill", cor: .yellow,
                       valor: "\(viewModel.premiosConquistados)",
                       unidade: "de \(viewModel.premios.count)")
            }
            .buttonStyle(.plain)
        }
    }

    private var cartaoSemana: some View {
        Button { mostrarSemana = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(CoresAneis.semana)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sua semana").font(.headline)
                    Text("Veja como foi a semana passada")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func cartao(titulo: String, icone: String, cor: Color, valor: String, unidade: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(titulo, systemImage: icone)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(cor)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(valor).font(Estilo.numero(30))
                Text(unidade).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
    }

    // "Quinta-feira, 22 de outubro" — só a primeira letra maiúscula
    private var dataDeHoje: String {
        let texto = Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "pt_BR")))
        return texto.prefix(1).uppercased() + texto.dropFirst()
    }

    private func inicialDoDia(_ dia: String) -> String {
        guard let data = DataUtil.data(de: dia) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: data).uppercased()
    }
}
