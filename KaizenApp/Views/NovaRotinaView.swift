import SwiftUI

struct NovaRotinaView: View {
    @ObservedObject var viewModel: RotinaViewModel
    @Environment(\.dismiss) var dismiss

    @State private var nome = ""
    @State private var descricao = ""
    @State private var frequencia = "Diária"
    @State private var mostrarConfirmacao = false

    let opcoesFrequencia = ["Diária", "Semanal", "Mensal"]

    var body: some View {
        Form {
            Section("Informações da rotina") {
                TextField("Nome da rotina", text: $nome)
                TextField("Descrição", text: $descricao)
            }

            Section("Frequência") {
                Picker("Frequência", selection: $frequencia) {
                    ForEach(opcoesFrequencia, id: \.self) { opcao in
                        Text(opcao).tag(opcao)
                    }
                }
                .pickerStyle(.inline)
            }

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
        viewModel.adicionar(nome: nome, descricao: descricao, frequencia: frequencia)
        mostrarConfirmacao = true
    }
}
