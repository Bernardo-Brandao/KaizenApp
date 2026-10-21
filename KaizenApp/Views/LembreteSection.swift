import SwiftUI

// Seção de formulário do lembrete (usada em Nova e Editar).
// Semanal pede o dia da semana; Mensal pede o dia do mês.
struct LembreteSection: View {
    let frequencia: String
    @Binding var lembreteAtivo: Bool
    @Binding var horario: Date
    @Binding var dia: Int

    // Calendar.weekday: 1 = domingo … 7 = sábado
    private let diasDaSemana = ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]

    private var tituloToggle: String {
        switch frequencia {
        case "Semanal": return "Ativar lembrete semanal"
        case "Mensal": return "Ativar lembrete mensal"
        default: return "Ativar lembrete diário"
        }
    }

    var body: some View {
        Section {
            Toggle(tituloToggle, isOn: $lembreteAtivo)
            if lembreteAtivo {
                if frequencia == "Semanal" {
                    Picker("Dia da semana", selection: $dia) {
                        ForEach(1...7, id: \.self) { numero in
                            Text(diasDaSemana[numero - 1]).tag(numero)
                        }
                    }
                } else if frequencia == "Mensal" {
                    Picker("Dia do mês", selection: $dia) {
                        ForEach(1...28, id: \.self) { numero in
                            Text("Dia \(numero)").tag(numero)
                        }
                    }
                }
                DatePicker("Horário", selection: $horario, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Lembrete")
        } footer: {
            if lembreteAtivo && frequencia == "Mensal" {
                Text("Vai até o dia 28 para o lembrete tocar em todos os meses.")
            }
        }
        // Ao trocar a frequência, o dia escolhido pode não fazer sentido (ex.: dia 20 numa rotina semanal)
        .onChange(of: frequencia) { _, nova in
            if nova == "Semanal" && dia > 7 { dia = 1 }
        }
    }
}
