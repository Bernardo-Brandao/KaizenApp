import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Intent: tocar numa tarefa do widget marca/desmarca sem abrir o app

struct AlternarTarefaIntent: AppIntent {
    static let title: LocalizedStringResource = "Marcar tarefa"
    static let isDiscoverable = false   // só pelo widget, não aparece no app Atalhos

    @Parameter(title: "Tarefa") var tarefaId: Int
    @Parameter(title: "Rotina") var rotinaId: Int

    init() {}

    init(tarefaId: Int64, rotinaId: Int64) {
        self.tarefaId = Int(tarefaId)
        self.rotinaId = Int(rotinaId)
    }

    func perform() async throws -> some IntentResult {
        ConclusaoTarefa.alternar(tarefaId: Int64(tarefaId), rotinaId: Int64(rotinaId))
        return .result()   // o WidgetKit redesenha o widget depois do perform
    }
}

// MARK: - Widget "Tarefas": as tarefas da próxima rotina pendente, com toque pra marcar

struct TarefasWidgetView: View {
    let entrada: EntradaKaizen
    @Environment(\.widgetFamily) private var familia

    // Próxima rotina pendente; se todas estiverem completas, a primeira (pra poder desmarcar)
    private var rotina: ResumoRotina? {
        let comTarefas = entrada.rotinas.filter { $0.total > 0 }
        return comTarefas.first { !$0.completa(em: entrada.date) } ?? comTarefas.first
    }

    private var limite: Int { familia == .systemLarge ? 8 : 3 }

    var body: some View {
        Group {
            if let rotina {
                conteudo(rotina)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundStyle(CoresWidget.primaria)
                    Text("Crie uma rotina com tarefas no Kaizen")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func conteudo(_ rotina: ResumoRotina) -> some View {
        let concluidas = rotina.concluidas(em: entrada.date)
        let cor = rotina.corHex.map(CoresWidget.hex) ?? CoresWidget.primaria
        // Se o período virou desde a última leitura, mostra tudo desmarcado
        let periodoVirou = entrada.date >= rotina.validoAte

        return VStack(alignment: .leading, spacing: 8) {
            Link(destination: LinkKaizen.rotina(rotina.id)) {
                HStack {
                    Text(rotina.nome)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    if rotina.completa(em: entrada.date) {
                        Label("Completa", systemImage: "checkmark.seal.fill")
                            .font(.caption.bold())
                            .foregroundStyle(cor)
                    } else {
                        Text("\(concluidas)/\(rotina.total)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ForEach(rotina.tarefas.prefix(limite)) { tarefa in
                let feita = tarefa.concluida && !periodoVirou
                Button(intent: AlternarTarefaIntent(tarefaId: tarefa.id, rotinaId: rotina.id)) {
                    HStack(spacing: 8) {
                        Image(systemName: feita ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(feita ? cor : .secondary)
                        Text(tarefa.nome)
                            .font(.subheadline)
                            .strikethrough(feita)
                            .foregroundStyle(feita ? .secondary : .primary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if rotina.total > limite {
                Text("+\(rotina.total - limite) tarefas no app")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct TarefasWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "KaizenTarefas", provider: ProvedorKaizen()) { entrada in
            TarefasWidgetView(entrada: entrada)
        }
        .configurationDisplayName("Tarefas")
        .description("Marque as tarefas da próxima rotina pendente direto na tela de início.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
