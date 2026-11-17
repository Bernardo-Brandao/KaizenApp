import SwiftUI
import Combine

struct BarraInferior: View {
    @Binding var aba: KaizenAppApp.Aba

    private let itens: [(aba: KaizenAppApp.Aba, titulo: String, icone: String)] = [
        (.hoje, "Hoje", "sun.horizon"),
        (.resumo, "Resumo", "chart.bar"),
        (.rotinas, "Rotinas", "checklist"),
        (.ajustes, "Ajustes", "gearshape"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(itens, id: \.aba) { item in
                let atual = item.aba == aba
                Button { aba = item.aba } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icone)
                            .font(.system(size: 19, weight: atual ? .medium : .light))
                            .symbolVariant(atual ? .fill : .none)
                            .frame(height: 24)
                        Text(item.titulo)
                            .font(.caption2.weight(atual ? .semibold : .regular))
                        Circle()
                            .fill(Paleta.destaque)
                            .frame(width: 4, height: 4)
                            .opacity(atual ? 1 : 0)
                    }
                    .foregroundStyle(atual ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.titulo)
                .accessibilityAddTraits(atual ? .isSelected : [])
            }
        }
        .padding(.bottom, 2)
        .background(.bar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
        }
        .sensoryFeedback(.selection, trigger: aba)
        .animation(.easeOut(duration: 0.15), value: aba)
    }
}

struct ComBarraInferior: ViewModifier {
    @Binding var aba: KaizenAppApp.Aba
    @State private var tecladoAberto = false

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !tecladoAberto {
                    BarraInferior(aba: $aba)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                tecladoAberto = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                tecladoAberto = false
            }
    }
}

extension View {
    func comBarraInferior(_ aba: Binding<KaizenAppApp.Aba>) -> some View {
        modifier(ComBarraInferior(aba: aba))
    }
}
