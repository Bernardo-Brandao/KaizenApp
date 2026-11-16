import SwiftUI

// Anotar o valor de uma tarefa de valor (ex.: água): número grande, campo pra digitar e somas rápidas
struct AnotarValorView: View {
    let tarefa: Tarefa
    var cor: Color = Paleta.destaque
    let aoSalvar: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var texto = ""
    @FocusState private var focado: Bool

    private var valor: Double { NumeroUtil.ler(texto) ?? 0 }
    private var unidade: String { tarefa.ehContagem ? "vezes" : tarefa.unidade }

    // Somas rápidas: um quarto e metade da meta (em quartos se a meta for pequena), ou 1 e 5 sem meta
    private var passos: [Double] {
        if tarefa.ehContagem { return [1] }
        guard let meta = tarefa.meta, meta > 0 else { return [1, 5] }
        func redondo(_ v: Double) -> Double { v < 10 ? (v * 4).rounded() / 4 : v.rounded() }
        return Array(Set([redondo(meta / 4), redondo(meta / 2)].filter { $0 > 0 })).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Número grande e, com meta, uma barra fina com o progresso do valor digitado
                VStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(NumeroUtil.formatar(valor)).font(Estilo.numero(48))
                        if let meta = tarefa.meta {
                            Text("de \(NumeroUtil.formatar(meta)) \(unidade)")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        } else if !unidade.isEmpty {
                            Text(unidade).font(.title3).foregroundStyle(.secondary)
                        }
                    }
                    if let meta = tarefa.meta, meta > 0 {
                        BarraProgresso(progresso: valor / meta, cor: cor)
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.top, 16)

                HStack(spacing: 10) {
                    TextField("0", text: $texto)
                        .keyboardType(.decimalPad)
                        .focused($focado)
                        .font(.title2.monospacedDigit())
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                    if !unidade.isEmpty {
                        Text(unidade).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 40)

                // Somas rápidas pra ir anotando ao longo do dia
                HStack(spacing: 10) {
                    ForEach(passos, id: \.self) { passo in
                        Button("+\(NumeroUtil.formatar(passo))") {
                            texto = NumeroUtil.formatar(valor + passo)
                        }
                        .buttonStyle(.bordered)
                        .tint(cor)
                    }
                    if let meta = tarefa.meta {
                        Button("Meta") { texto = NumeroUtil.formatar(meta) }
                            .buttonStyle(.bordered)
                            .tint(cor)
                    }
                    Button("Zerar") { texto = "" }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                }
                .font(.subheadline.weight(.semibold))

                if !tarefa.saude.isEmpty {
                    Label("Preenchida pelo app Saúde ao abrir o Kaizen", systemImage: "heart.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(tarefa.nome)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        aoSalvar(valor)
                        dismiss()
                    }
                }
            }
            .onAppear {
                texto = tarefa.valorAtual > 0 ? NumeroUtil.formatar(tarefa.valorAtual) : ""
            }
            .sensoryFeedback(.selection, trigger: texto)
        }
    }
}
