import SwiftUI

struct CampoHorario: View {
    @Binding var horario: String
    var titulo = "Lembrete"
    var icone = "bell"

    private static let formato: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private var ligado: Binding<Bool> {
        Binding(
            get: { !horario.isEmpty },
            set: { liga in horario = liga ? Self.formato.string(from: Self.proximaHoraCheia()) : "" }
        )
    }

    private var data: Binding<Date> {
        Binding(
            get: { Self.formato.date(from: horario) ?? Self.proximaHoraCheia() },
            set: { horario = Self.formato.string(from: $0) }
        )
    }

    var body: some View {
        Toggle(isOn: ligado) {
            Label(titulo, systemImage: icone)
        }
        if ligado.wrappedValue {
            DatePicker("Horário", selection: data, displayedComponents: .hourAndMinute)
        }
    }

    private static func proximaHoraCheia() -> Date {
        let calendario = Calendar.current
        let agora = Date()
        let hora = calendario.component(.hour, from: agora)
        return calendario.date(bySettingHour: (hora + 1) % 24, minute: 0, second: 0, of: agora) ?? agora
    }
}

struct EtiquetaHorario: View {
    let horario: String
    var cor: Color = .secondary

    var body: some View {
        Label(horario, systemImage: "bell.fill")
            .font(.caption2.weight(.medium).monospacedDigit())
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(.tertiarySystemFill), in: Capsule())
            .foregroundStyle(cor)
            .accessibilityLabel("Lembrete às \(horario)")
    }
}

struct CampoTipoTarefa: View {
    @Binding var tipo: String
    @Binding var unidade: String
    @Binding var meta: String
    @Binding var saude: String
    var frequencia = "Diária"

    var body: some View {
        Picker("Tipo", selection: $tipo) {
            Label("Marcar", systemImage: "checkmark.square").tag("check")
            Label("Valor", systemImage: "number").tag("valor")
            Label("Vezes", systemImage: "repeat").tag("vezes")
        }
        .pickerStyle(.segmented)
        if tipo == "valor" {
            if SaudeService.disponivel {
                Picker(selection: $saude) {
                    Text("Anotar à mão").tag("")
                    ForEach(MetricaSaude.allCases) { metrica in
                        Label(metrica.titulo, systemImage: metrica.icone).tag(metrica.rawValue)
                    }
                } label: {
                    Label("App Saúde", systemImage: "heart")
                }
                .onChange(of: saude) { _, nova in
                    guard let metrica = MetricaSaude(rawValue: nova) else { return }
                    unidade = metrica.unidade
                    if meta.isEmpty { meta = NumeroUtil.formatar(metrica.metaSugerida) }
                    Task { await SaudeService.autorizar([metrica]) }
                }
            }
            TextField("Unidade (ex.: L, páginas, min)", text: $unidade)
                .disabled(!saude.isEmpty)
            TextField("Meta (opcional, ex.: 3)", text: $meta)
                .keyboardType(.decimalPad)
        } else if tipo == "vezes" {
            TextField("Quantas vezes \(Self.periodo(frequencia))? (ex.: 3)", text: $meta)
                .keyboardType(.numberPad)
        }
    }

    static func periodo(_ frequencia: String) -> String {
        switch frequencia {
        case "Semanal": "na semana"
        case "Mensal": "no mês"
        default: "por dia"
        }
    }

    static func explicacao(_ tipo: String, frequencia: String) -> String {
        switch tipo {
        case "valor":
            "Você anota um número (ex.: água 3 L) ou deixa o app Saúde preencher (passos, água, exercício, sono). Com meta, a tarefa fica feita ao bater a meta."
        case "vezes":
            frequencia == "Diária"
                ? "Cada toque soma 1. Pra algo como \"academia 3 vezes na semana\", use uma rotina semanal: a contagem vale a semana toda."
                : "Cada toque soma 1 e a contagem vale \(frequencia == "Mensal" ? "o mês" : "a semana") inteira. Fica feita ao bater a meta."
        default:
            "Uma checkbox: feito ou não feito."
        }
    }
}
