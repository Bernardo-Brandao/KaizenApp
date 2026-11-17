import SwiftUI

enum Paleta {
    static let destaque = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.47, blue: 0.36, alpha: 1)
            : UIColor(red: 0.89, green: 0.37, blue: 0.24, alpha: 1)
    })
    static let trilha = Color(.tertiarySystemFill)
}

struct CirculoProgresso: View {
    let progresso: Double
    var cor: Color = Paleta.destaque
    var animado = true

    @State private var exibido: Double = 0

    private var valor: Double { min(max(animado ? exibido : progresso, 0), 1) }

    var body: some View {
        GeometryReader { geo in
            let lado = min(geo.size.width, geo.size.height)
            let linha = max(1.2, lado * 0.07)
            ZStack {
                Circle().strokeBorder(cor.opacity(0.55), lineWidth: linha)
                Fatia(fracao: valor)
                    .fill(cor)
                    .padding(linha * 2)
            }
            .frame(width: lado, height: lado)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(progresso * 100))%")
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { exibido = progresso }
        }
        .onChange(of: progresso) { _, novo in
            withAnimation(.easeOut(duration: 0.35)) { exibido = novo }
        }
    }
}

struct Fatia: Shape {
    var fracao: Double

    var animatableData: Double {
        get { fracao }
        set { fracao = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var caminho = Path()
        guard fracao > 0 else { return caminho }
        let centro = CGPoint(x: rect.midX, y: rect.midY)
        caminho.move(to: centro)
        caminho.addArc(center: centro, radius: min(rect.width, rect.height) / 2,
                       startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * fracao), clockwise: false)
        caminho.closeSubpath()
        return caminho
    }
}

struct BarraProgresso: View {
    let progresso: Double
    var cor: Color = Paleta.destaque
    var altura: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Paleta.trilha)
                Capsule()
                    .fill(cor)
                    .frame(width: progresso > 0 ? max(altura, geo.size.width * min(progresso, 1)) : 0)
            }
        }
        .frame(height: altura)
        .animation(.easeOut(duration: 0.35), value: progresso)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(progresso * 100))%")
    }
}
