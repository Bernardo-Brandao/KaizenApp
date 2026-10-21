import SwiftUI

struct NovaRotinaView: View {
    @ObservedObject var viewModel: RotinaViewModel
    @Environment(\.dismiss) var dismiss

    @State private var nome = ""
    @State private var descricao = ""
    @State private var frequencia = "Diária"
    @State private var lembreteAtivo = false
    @State private var horarioLembrete = Date()
    @State private var categoriaId: Int64?
    @State private var diaLembrete = 1
    @State private var mostrarConfirmacao = false

    let opcoesFrequencia = ["Diária", "Semanal", "Mensal"]

    var body: some View {
        Form {
            Section("Informações da rotina") {
                TextField("Nome da rotina", text: $nome)
                TextField("Descrição", text: $descricao)
            }

            CategoriaPickerSection(categoriaId: $categoriaId)

            Section("Frequência") {
                Picker("Frequência", selection: $frequencia) {
                    ForEach(opcoesFrequencia, id: \.self) { opcao in
                        Text(opcao).tag(opcao)
                    }
                }
                .pickerStyle(.inline)
            }

            LembreteSection(
                frequencia: frequencia,
                lembreteAtivo: $lembreteAtivo,
                horario: $horarioLembrete,
                dia: $diaLembrete
            )

            Section {
                Button("Salvar rotina") {
                    salvar()
                }
                .disabled(nome.isEmpty)
            }
        }
        .navigationTitle("Nova Rotina")
        .alert("Rotina salva!", isPresented: $mostrarConfirmacao) {
            Button("OK") { dismiss() }
        }
    }

    func salvar() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let horarioTexto = lembreteAtivo ? formatter.string(from: horarioLembrete) : ""

        viewModel.adicionar(
            nome: nome,
            descricao: descricao,
            frequencia: frequencia,
            horarioLembrete: horarioTexto,
            lembreteAtivo: lembreteAtivo,
            diaLembrete: diaLembrete,
            categoriaId: categoriaId
        )
        mostrarConfirmacao = true
    }
}
