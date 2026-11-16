import SwiftUI

// Seção de lembretes da rotina (Nova e Editar). Os horários ficam em cada tarefa;
// aqui só se escolhe o dia, em rotinas semanais (dia da semana) e mensais (dia do mês).
struct LembreteSection: View {
    let frequencia: String
    @Binding var dia: Int

    // Calendar.weekday: 1 = domingo … 7 = sábado
    private let diasDaSemana = ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]

    var body: some View {
        Section {
            if frequencia == "Semanal" {
                Picker("Dia dos lembretes", selection: $dia) {
                    ForEach(1...7, id: \.self) { numero in
                        Text(diasDaSemana[numero - 1]).tag(numero)
                    }
                }
            } else if frequencia == "Mensal" {
                Picker("Dia dos lembretes", selection: $dia) {
                    ForEach(1...28, id: \.self) { numero in
                        Text("Dia \(numero)").tag(numero)
                    }
                }
            }
        } header: {
            Text("Lembretes")
        } footer: {
            switch frequencia {
            case "Semanal": Text("Os lembretes tocam nesse dia, no horário de cada tarefa. Defina o horário ao criar ou editar a tarefa.")
            case "Mensal": Text("Vai até o dia 28 pra tocar todo mês. O horário fica em cada tarefa.")
            default: Text("O horário do lembrete fica em cada tarefa: defina ao criar ou editar a tarefa.")
            }
        }
        // Ao trocar a frequência, o dia escolhido pode não fazer sentido (ex.: dia 20 numa rotina semanal)
        .onChange(of: frequencia) { _, nova in
            if nova == "Semanal" && dia > 7 { dia = 1 }
        }
    }
}
