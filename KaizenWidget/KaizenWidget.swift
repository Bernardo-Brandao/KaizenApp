import SwiftUI
import WidgetKit

// MARK: - Timeline

struct EntradaKaizen: TimelineEntry {
    let date: Date
    let rotinas: [ResumoRotina]
}

struct ProvedorKaizen: TimelineProvider {
    func placeholder(in context: Context) -> EntradaKaizen {
        EntradaKaizen(date: .now, rotinas: Self.exemplo)
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaKaizen) -> Void) {
        let rotinas = ResumoWidget.carregar()
        completion(EntradaKaizen(date: .now, rotinas: context.isPreview && rotinas.isEmpty ? Self.exemplo : rotinas))
    }

    // Uma entrada agora e outra em cada virada de período, pra o progresso zerar
    // na hora certa mesmo se o app não for aberto
    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaKaizen>) -> Void) {
        let rotinas = ResumoWidget.carregar()
        let viradas = Set(rotinas.map(\.validoAte)).filter { $0 > .now }.sorted()
        let entradas = ([Date.now] + viradas).map { EntradaKaizen(date: $0, rotinas: rotinas) }
        completion(Timeline(entries: entradas, policy: .atEnd))
    }

    // Dados de exemplo pra galeria de widgets, quando ainda não há rotinas
    static let exemplo = [
        exemplo(1, "Manhã", feitas: 3, de: ["Água", "Alongar", "Meditar"], cor: nil),
        exemplo(2, "Estudos", feitas: 1, de: ["Ler 20 páginas", "Revisar", "Exercícios", "Resumo"], cor: "AF52DE"),
        exemplo(3, "Academia", feitas: 0, de: ["Treino", "Proteína"], cor: "34C759"),
    ]

    private static func exemplo(_ id: Int64, _ nome: String, feitas: Int, de nomes: [String], cor: String?) -> ResumoRotina {
        let tarefas = nomes.enumerated().map { indice, nomeTarefa in
            ResumoTarefa(id: Int64(id * 100 + Int64(indice)), nome: nomeTarefa, concluida: indice < feitas)
        }
        return ResumoRotina(id: id, nome: nome, tarefas: tarefas, corHex: cor, validoAte: .distantFuture)
    }
}

// MARK: - Views

struct KaizenWidgetView: View {
    let entrada: EntradaKaizen
    @Environment(\.widgetFamily) private var familia

    // Só rotinas com tarefas entram na conta
    private var rotinas: [ResumoRotina] {
        entrada.rotinas.filter { $0.total > 0 && $0.programadaHoje }
    }

    private var completas: Int {
        rotinas.filter { $0.completa(em: entrada.date) }.count
    }

    var body: some View {
        Group {
            switch familia {
            case .accessoryCircular: bloqueioCircular
            case .accessoryRectangular: bloqueioRetangular
            case .accessoryInline: bloqueioEmLinha
            default: telaInicial
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(urlDoToque)
    }

    // Toque no widget: o retangular abre a rotina pendente; os outros abrem a lista.
    // No médio, cada linha tem o próprio Link e abre a rotina dela.
    private var urlDoToque: URL {
        if familia == .accessoryRectangular,
           let pendente = rotinas.first(where: { !$0.completa(em: entrada.date) }) {
            return LinkKaizen.rotina(pendente.id)
        }
        return LinkKaizen.lista
    }

    @ViewBuilder
    private var telaInicial: some View {
        Group {
            if rotinas.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundStyle(CoresWidget.primaria)
                    Text("Crie uma rotina no Kaizen")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            } else if familia == .systemSmall {
                resumoGeral
            } else {
                lista
            }
        }
    }

    // MARK: - Tela de bloqueio (o sistema aplica as cores; aqui é só forma e texto)

    private var bloqueioCircular: some View {
        Gauge(value: Double(completas), in: 0...Double(max(rotinas.count, 1))) {
            Image(systemName: "checklist")
        } currentValueLabel: {
            if !rotinas.isEmpty && completas == rotinas.count {
                Image(systemName: "checkmark")
            } else {
                Text("\(completas)/\(rotinas.count)")
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
    }

    // Próxima rotina com tarefa pendente; se não houver, "Tudo feito!"
    private var bloqueioRetangular: some View {
        let pendente = rotinas.first { !$0.completa(em: entrada.date) }
        return VStack(alignment: .leading, spacing: 2) {
            Label("Kaizen", systemImage: "checklist")
                .font(.caption2.weight(.semibold))
                .widgetAccentable()
            if rotinas.isEmpty {
                Text("Nenhuma rotina").font(.headline)
            } else if let pendente {
                Text(pendente.nome)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(pendente.concluidas(em: entrada.date))/\(pendente.total) tarefas · \(completas)/\(rotinas.count) rotinas")
                    .font(.caption)
                    .lineLimit(1)
            } else {
                Text("Tudo feito!").font(.headline)
                Text("\(rotinas.count) de \(rotinas.count) rotinas").font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bloqueioEmLinha: some View {
        Label(rotinas.isEmpty ? "Kaizen" : "\(completas) de \(rotinas.count) rotinas",
              systemImage: "checklist")
    }

    // Fração de tarefas feitas nas rotinas de uma frequência (anéis: hoje, semana, mês)
    private func fracao(_ frequencia: String) -> Double {
        let daFrequencia = rotinas.filter { $0.frequencia == frequencia }
        let total = daFrequencia.reduce(0) { $0 + $1.total }
        guard total > 0 else { return 0 }
        return Double(daFrequencia.reduce(0) { $0 + $1.concluidas(em: entrada.date) }) / Double(total)
    }

    private func aneis(tamanho: CGFloat) -> some View {
        AneisAtividade(hoje: fracao("Diária"), semana: fracao("Semanal"), mes: fracao("Mensal"),
                       tamanho: tamanho, animado: false)
    }

    // Pequeno: os três anéis do Resumo e quantas rotinas estão completas
    private var resumoGeral: some View {
        VStack(spacing: 6) {
            aneis(tamanho: 104)
            Text(completas == rotinas.count ? "Tudo feito!" : "\(completas) de \(rotinas.count) rotinas")
                .font(.caption.weight(.semibold))
                .foregroundStyle(completas == rotinas.count ? CoresAneis.hoje : .secondary)
        }
    }

    // Médio: anéis à esquerda e as rotinas (com emoji) à direita
    private var lista: some View {
        HStack(spacing: 16) {
            aneis(tamanho: 112)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rotinas.prefix(3)) { rotina in
                    let concluidas = rotina.concluidas(em: entrada.date)
                    let cor = rotina.corHex.map(CoresWidget.hex) ?? cor(daFrequencia: rotina.frequencia)
                    Link(destination: LinkKaizen.rotina(rotina.id)) {
                        HStack(spacing: 6) {
                            Text(rotina.icone.isEmpty ? "📋" : rotina.icone)
                                .font(.subheadline)
                            Text(rotina.nome)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            if rotina.completa(em: entrada.date) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(cor)
                            } else {
                                Text("\(concluidas)/\(rotina.total)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if rotinas.count > 3 {
                    Text("+\(rotinas.count - 3) rotinas")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func cor(daFrequencia frequencia: String) -> Color {
        switch frequencia {
        case "Semanal": return CoresAneis.semana
        case "Mensal": return CoresAneis.mes
        default: return CoresAneis.hoje
        }
    }
}

// Links que o app trata em KaizenAppApp.onOpenURL
enum LinkKaizen {
    static let lista = URL(string: "kaizen://rotinas")!
    static func rotina(_ id: Int64) -> URL { URL(string: "kaizen://rotina/\(id)")! }
}

// O widget não enxerga o AppTheme do app; a cor principal é a mesma (3DA9FC)
enum CoresWidget {
    static let primaria = hex("3DA9FC")

    static func hex(_ valor: String) -> Color {
        var numero: UInt64 = 0
        Scanner(string: valor.trimmingCharacters(in: CharacterSet(charactersIn: "#"))).scanHexInt64(&numero)
        return Color(
            red: Double((numero >> 16) & 0xFF) / 255,
            green: Double((numero >> 8) & 0xFF) / 255,
            blue: Double(numero & 0xFF) / 255
        )
    }
}

// MARK: - Widget

@main
struct KaizenWidgets: WidgetBundle {
    var body: some Widget {
        KaizenWidget()
        TarefasWidget()
    }
}

struct KaizenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "KaizenWidget", provider: ProvedorKaizen()) { entrada in
            KaizenWidgetView(entrada: entrada)
        }
        .configurationDisplayName("Rotinas")
        .description("Progresso das suas rotinas no período atual.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
