import SwiftUI

// Sete bolinhas (D S T Q Q S S) pra escolher os dias. Conjunto vazio = todos os dias.
// Não deixa desmarcar o último dia — sem nenhum dia, a rotina/tarefa nunca apareceria.
struct SeletorDiasSemana: View {
    @Binding var dias: Set<Int>
    var cor: Color = AppTheme.primary

    private var marcados: Set<Int> { dias.isEmpty ? DiasSemana.todos : dias }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { dia in
                let marcado = marcados.contains(dia)
                Button {
                    var novos = marcados
                    if marcado { novos.remove(dia) } else { novos.insert(dia) }
                    guard !novos.isEmpty else { return }
                    dias = DiasSemana.normalizar(novos)
                } label: {
                    Text(DiasSemana.iniciais[dia - 1])
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(marcado ? cor : Color(.tertiarySystemFill)))
                        .foregroundStyle(marcado ? .white : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(DiasSemana.nomesCurtos[dia - 1])
                .accessibilityAddTraits(marcado ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: dias)
    }
}
