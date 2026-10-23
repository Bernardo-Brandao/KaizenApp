import SwiftUI

// Anéis no estilo do app Fitness, usados no app e nos widgets.
// Uma cor por frequência: hoje (vermelho), semana (verde), mês (azul).
enum CoresAneis {
    static let hoje = Color(red: 1.0, green: 0.176, blue: 0.333)      // FF2D55
    static let semana = Color(red: 0.188, green: 0.82, blue: 0.345)   // 30D158
    static let mes = Color(red: 0.039, green: 0.518, blue: 1.0)       // 0A84FF
}

// Anel de progresso com trilha de fundo (o anel "vazio" na mesma cor, bem clara)
struct AnelProgresso: View {
    let progresso: Double
    let cor: Color
    var espessura: CGFloat = 10
    var animado = true   // no widget não há animação: desenha direto o valor final

    @State private var exibido: Double = 0

    private var valor: Double { animado ? exibido : progresso }

    var body: some View {
        ZStack {
            Circle()
                .stroke(cor.opacity(0.18), lineWidth: espessura)
            Circle()
                .trim(from: 0, to: max(0.001, min(valor, 1)))
                .stroke(cor, style: StrokeStyle(lineWidth: espessura, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(espessura / 2)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) { exibido = progresso }
        }
        .onChange(of: progresso) { _, novo in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { exibido = novo }
        }
    }
}

// Três anéis concêntricos: hoje (fora), semana (meio), mês (dentro)
struct AneisAtividade: View {
    let hoje: Double
    let semana: Double
    let mes: Double
    var tamanho: CGFloat = 150
    var animado = true

    var body: some View {
        let espessura = tamanho * 0.11
        let passo = espessura * 2 + 2
        ZStack {
            AnelProgresso(progresso: hoje, cor: CoresAneis.hoje, espessura: espessura, animado: animado)
                .frame(width: tamanho, height: tamanho)
            AnelProgresso(progresso: semana, cor: CoresAneis.semana, espessura: espessura, animado: animado)
                .frame(width: tamanho - passo, height: tamanho - passo)
            AnelProgresso(progresso: mes, cor: CoresAneis.mes, espessura: espessura, animado: animado)
                .frame(width: tamanho - passo * 2, height: tamanho - passo * 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hoje \(Int(hoje * 100))%, semana \(Int(semana * 100))%, mês \(Int(mes * 100))%")
    }
}
