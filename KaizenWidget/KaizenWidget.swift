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

    static let exemplo = [
        ResumoRotina(id: 1, nome: "Manhã", concluidas: 3, total: 3, corHex: nil, validoAte: .distantFuture),
        ResumoRotina(id: 2, nome: "Estudos", concluidas: 1, total: 4, corHex: "AF52DE", validoAte: .distantFuture),
        ResumoRotina(id: 3, nome: "Academia", concluidas: 0, total: 2, corHex: "34C759", validoAte: .distantFuture),
    ]
}

// MARK: - Views

struct KaizenWidgetView: View {
    let entrada: EntradaKaizen
    @Environment(\.widgetFamily) private var familia

    // Só rotinas com tarefas entram na conta
    private var rotinas: [ResumoRotina] {
        entrada.rotinas.filter { $0.total > 0 }
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
    }

    @ViewBuilder
    private var telaInicial: some View {
        Group {
            if rotinas.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundStyle(Cores.primaria)
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

    private var resumoGeral: some View {
        VStack(spacing: 8) {
            ZStack {
                Anel(progresso: Double(completas) / Double(rotinas.count), cor: Cores.primaria, espessura: 8)
                if completas == rotinas.count {
                    Image(systemName: "checkmark")
                        .font(.title3.bold())
                        .foregroundStyle(Cores.primaria)
                } else {
                    Text("\(completas)/\(rotinas.count)")
                        .font(.title3.bold().monospacedDigit())
                }
            }
            .frame(width: 70, height: 70)
            Text(completas == 1 ? "rotina completa" : "rotinas completas")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var lista: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(rotinas.prefix(4)) { rotina in
                let concluidas = rotina.concluidas(em: entrada.date)
                let cor = rotina.corHex.map(Cores.hex) ?? Cores.primaria
                HStack(spacing: 8) {
                    Anel(progresso: Double(concluidas) / Double(rotina.total), cor: cor, espessura: 3)
                        .frame(width: 18, height: 18)
                    Text(rotina.nome)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text("\(concluidas)/\(rotina.total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            if rotinas.count > 4 {
                Text("+\(rotinas.count - 4) rotinas")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct Anel: View {
    let progresso: Double
    let cor: Color
    let espessura: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(cor.opacity(0.2), lineWidth: espessura)
            Circle()
                .trim(from: 0, to: progresso)
                .stroke(cor, style: StrokeStyle(lineWidth: espessura, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// O widget não enxerga o AppTheme do app; a cor principal é a mesma (3DA9FC)
private enum Cores {
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
