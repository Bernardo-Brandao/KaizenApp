import SwiftUI
import WidgetKit

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

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaKaizen>) -> Void) {
        let agora = Date.now
        let rotinas = ResumoWidget.carregar()
        let proximaVirada = rotinas.map(\.validoAte).filter { $0 > agora }.min()
        let releitura = min(proximaVirada ?? .distantFuture, agora.addingTimeInterval(Self.intervaloReleitura))
        let entradas = ([agora] + [proximaVirada].compactMap { $0 }).map { EntradaKaizen(date: $0, rotinas: rotinas) }
        completion(Timeline(entries: entradas, policy: .after(releitura)))
    }

    static let intervaloReleitura: TimeInterval = 30 * 60

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

struct KaizenWidgetView: View {
    let entrada: EntradaKaizen
    @Environment(\.widgetFamily) private var familia

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
                        .foregroundStyle(Paleta.destaque)
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

    private var tarefasFeitas: Int { rotinas.reduce(0) { $0 + $1.concluidas(em: entrada.date) } }
    private var totalTarefas: Int { rotinas.reduce(0) { $0 + $1.total } }

    private var painel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hoje")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(tarefasFeitas)").font(.system(size: 38, weight: .semibold))
                Text("/\(totalTarefas)").font(.title3).foregroundStyle(.secondary)
            }
            BarraProgresso(progresso: totalTarefas > 0 ? Double(tarefasFeitas) / Double(totalTarefas) : 0)
        }
    }

    private var resumoGeral: some View {
        VStack(alignment: .leading, spacing: 0) {
            painel
            Spacer(minLength: 6)
            Text(completas == rotinas.count ? "Tudo feito!" : "\(completas) de \(rotinas.count) rotinas")
                .font(.caption.weight(.medium))
                .foregroundStyle(completas == rotinas.count ? Paleta.destaque : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lista: some View {
        HStack(spacing: 20) {
            painel
                .frame(width: 100)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rotinas.prefix(3)) { rotina in
                    let concluidas = rotina.concluidas(em: entrada.date)
                    let cor = rotina.corHex.map(CoresWidget.hex) ?? Paleta.destaque
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
}

enum LinkKaizen {
    static let lista = URL(string: "kaizen://rotinas")!
    static func rotina(_ id: Int64) -> URL { URL(string: "kaizen://rotina/\(id)")! }
}

enum CoresWidget {
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
