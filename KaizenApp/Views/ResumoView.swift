import SwiftUI

struct ResumoView: View {
    @StateObject private var viewModel = ResumoViewModel()
    @Binding var abaSelecionada: KaizenAppApp.Aba
    @Binding var mostrarSemana: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var mostrarModelos = false
    @StateObject private var rotinaViewModel = RotinaViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    cabecalho
                    painelHoje
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

    private var painelHoje: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hoje")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let hoje = ResumoViewModel.progresso(viewModel.rotinas, frequencia: "Diária") {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(hoje.feitas)").font(Estilo.numero(40))
                            Text("de \(hoje.total) tarefas")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Nada para hoje")
                            .font(.title3.weight(.semibold))
                            .padding(.vertical, 6)
                    }
                }
                Spacer()
                if let hoje = ResumoViewModel.progresso(viewModel.rotinas, frequencia: "Diária"), hoje.total > 0 {
                    Text("\(hoje.feitas * 100 / hoje.total)%")
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(hoje.feitas == hoje.total ? Paleta.destaque : .secondary)
                }
            }

            GraficoDias(dias: viewModel.semana, cor: Paleta.destaque)

            if !outrosPeriodos.isEmpty {
                Text(outrosPeriodos)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
    }

    private var outrosPeriodos: String {
        [("Semana", "Semanal"), ("Mês", "Mensal")].compactMap { titulo, frequencia in
            ResumoViewModel.progresso(viewModel.rotinas, frequencia: frequencia).map { "\(titulo) \($0.feitas) de \($0.total)" }
        }
        .joined(separator: "  ·  ")
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
                Text(!rotina.programadaHoje ? "Folga hoje"
                     : rotina.total == 0 ? "Sem tarefas" : "\(feitas) de \(rotina.total) · \(rotina.frequencia)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !rotina.programadaHoje {
                Image(systemName: "moon.zzz")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else if rotina.completa(em: .now) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(cor)
            } else if rotina.total > 0 {
                CirculoProgresso(progresso: Double(feitas) / Double(rotina.total), cor: cor)
                    .frame(width: 22, height: 22)
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
        HStack(spacing: 0) {
            numero(titulo: "Sequência", icone: "flame",
                   valor: "\(viewModel.melhorSequenciaAtual)",
                   unidade: viewModel.melhorSequenciaAtual == 1 ? "seguida" : "seguidas")
            Divider().padding(.vertical, 4)
            NavigationLink {
                PremiosView()
            } label: {
                numero(titulo: "Prêmios", icone: "trophy",
                       valor: "\(viewModel.premiosConquistados)",
                       unidade: "de \(viewModel.premios.count)")
                    .padding(.leading, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
    }

    private var cartaoSemana: some View {
        Button { mostrarSemana = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(.secondary)
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

    private func numero(titulo: String, icone: String, valor: String, unidade: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(titulo, systemImage: icone)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(valor).font(Estilo.numero(28))
                Text(unidade).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dataDeHoje: String {
        let texto = Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "pt_BR")))
        return texto.prefix(1).uppercased() + texto.dropFirst()
    }
}

struct GraficoDias: View {
    let dias: [DiaSemana]
    var cor: Color
    var altura: CGFloat = 72

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(dias) { dia in
                VStack(spacing: 6) {
                    ZStack(alignment: .bottom) {
                        Capsule().fill(Paleta.trilha)
                        if let progresso = dia.progresso, progresso > 0 {
                            Capsule()
                                .fill(cor.opacity(dia.ehHoje ? 1 : 0.45))
                                .frame(height: max(altura * progresso, 8))
                        }
                    }
                    .animation(.easeOut(duration: 0.4), value: dia.progresso)
                    .frame(width: 14, height: altura)
                    Text(Self.inicial(dia.data))
                        .font(.caption2.weight(dia.ehHoje ? .bold : .regular))
                        .foregroundStyle(dia.ehHoje ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(dia.data): \(dia.progresso.map { "\(Int($0 * 100))%" } ?? "sem registro")")
            }
        }
    }

    private static func inicial(_ dia: String) -> String {
        guard let data = DataUtil.data(de: dia) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: data).uppercased()
    }
}
