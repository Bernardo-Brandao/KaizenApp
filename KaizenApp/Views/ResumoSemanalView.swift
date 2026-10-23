import SwiftUI

// "Sua semana", no estilo do resumo semanal do Fitness: a semana que terminou (domingo a sábado)
struct ResumoSemanalView: View {
    @StateObject private var viewModel = ResumoSemanalViewModel()
    private let colunas = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            if let resumo = viewModel.resumo {
                if resumo.vazio {
                    ContentUnavailableView("Nada pra resumir ainda",
                                           systemImage: "calendar",
                                           description: Text("Crie rotinas diárias ou semanais e volte no domingo."))
                        .padding(.top, 60)
                } else {
                    conteudo(resumo)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sua semana")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.carregar() }
    }

    private func conteudo(_ resumo: ResumoSemanal) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Anel grande com a taxa da semana
            VStack(spacing: 12) {
                Text(intervalo(resumo))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ZStack {
                    AnelProgresso(progresso: resumo.taxa, cor: CoresAneis.semana, espessura: 18)
                        .frame(width: 170, height: 170)
                    VStack(spacing: 0) {
                        Text("\(Int((resumo.taxa * 100).rounded()))%").font(Estilo.numero(40))
                        Text("concluído").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let variacao = resumo.variacao {
                    comparacao(variacao)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))

            LazyVGrid(columns: colunas, spacing: 12) {
                cartao("Dias perfeitos", icone: "star.fill", cor: .yellow,
                       valor: "\(resumo.diasPerfeitos)", unidade: "de 7")
                cartao("Tarefas feitas", icone: "checkmark.circle.fill", cor: CoresAneis.hoje,
                       valor: "\(resumo.tarefasFeitas)", unidade: "")
            }
            if let melhor = resumo.melhorDia {
                cartao("Melhor dia", icone: "crown.fill", cor: .orange,
                       valor: nomeDoDia(melhor), unidade: "")
            }

            // Cada rotina: os 7 dias (diárias) ou a semana (semanais)
            VStack(alignment: .leading, spacing: 0) {
                Text("Rotinas").font(.headline).padding(.bottom, 8)
                ForEach(resumo.linhas) { linha in
                    HStack(spacing: 10) {
                        Text(linha.icone)
                        Text(linha.nome).lineLimit(1)
                        Spacer()
                        if linha.frequencia == "Diária" {
                            HStack(spacing: 4) {
                                ForEach(Array(linha.dias.enumerated()), id: \.offset) { _, feito in
                                    if let feito {
                                        Circle()
                                            .fill(feito ? CoresAneis.hoje : Color(.tertiarySystemFill))
                                            .frame(width: 12, height: 12)
                                    } else {
                                        // Folga: só o contorno
                                        Circle()
                                            .strokeBorder(Color(.tertiaryLabel), lineWidth: 1)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(linha.dias.filter { $0 == true }.count) de \(linha.dias.compactMap { $0 }.count) dias")
                        } else {
                            Label(linha.semanaCompleta ? "Completa" : "Incompleta",
                                  systemImage: linha.semanaCompleta ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundStyle(linha.semanaCompleta ? CoresAneis.semana : .secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    if linha.id != resumo.linhas.last?.id {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
        }
        .padding()
    }

    private func comparacao(_ variacao: Double) -> some View {
        let pontos = Int((variacao * 100).rounded())
        let (texto, icone, cor): (String, String, Color) = switch pontos {
        case 1...: ("\(pontos) pontos acima da semana anterior", "arrow.up.right", CoresAneis.semana)
        case ..<0: ("\(-pontos) pontos abaixo da semana anterior", "arrow.down.right", .orange)
        default: ("Igual à semana anterior", "equal", .secondary)
        }
        return Label(texto, systemImage: icone)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(cor)
    }

    private func cartao(_ titulo: String, icone: String, cor: Color, valor: String, unidade: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(titulo, systemImage: icone)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(cor)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(valor).font(Estilo.numero(28))
                if !unidade.isEmpty {
                    Text(unidade).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Estilo.cantoCartao))
    }

    // "12 a 18 de outubro"
    private func intervalo(_ resumo: ResumoSemanal) -> String {
        guard let inicio = DataUtil.data(de: resumo.inicio), let fim = DataUtil.data(de: resumo.fim) else { return "" }
        let dia = DateFormatter()
        dia.locale = Locale(identifier: "pt_BR")
        dia.dateFormat = "d"
        let completo = DateFormatter()
        completo.locale = Locale(identifier: "pt_BR")
        completo.dateFormat = "d 'de' MMMM"
        let mesmoMes = Calendar.current.component(.month, from: inicio) == Calendar.current.component(.month, from: fim)
        return "\((mesmoMes ? dia : completo).string(from: inicio)) a \(completo.string(from: fim))"
    }

    private func nomeDoDia(_ dia: String) -> String {
        guard let data = DataUtil.data(de: dia) else { return dia }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE"
        let nome = formatter.string(from: data)
        return nome.prefix(1).uppercased() + nome.dropFirst()
    }
}
