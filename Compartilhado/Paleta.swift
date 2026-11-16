import SwiftUI

// Cores do app e dos widgets: tons neutros e um único destaque, o coral do sol do ícone
enum Paleta {
    static let destaque = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.47, blue: 0.36, alpha: 1)   // F5785C
            : UIColor(red: 0.89, green: 0.37, blue: 0.24, alpha: 1)   // E35E3D
    })
    static let trilha = Color(.tertiarySystemFill)
}

// Progresso num círculo: contorno fino e uma fatia que vai enchendo (sem anel grosso)
struct CirculoProgresso: View {
    let progresso: Double
    var cor: Color = Paleta.destaque
    var animado = true   // no widget não há animação: desenha direto o valor final

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

// Fatia de pizza a partir do meio-dia, no sentido horário
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

// Barra fina de progresso, para os números grandes
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
