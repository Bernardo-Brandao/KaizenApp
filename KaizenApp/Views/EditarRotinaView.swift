import SwiftUI

struct EditarRotinaView: View {
    @ObservedObject var viewModel: RotinaViewModel
    @Environment(\.dismiss) var dismiss

    let rotina: Rotina

    @State private var nome: String
    @State private var descricao: String
    @State private var frequencia: String
    @State private var mostrarConfirmacao = false

    let opcoesFrequencia = ["Diária", "Semanal", "Mensal"]

    init(viewModel: RotinaViewModel, rotina: Rotina) {
        self.viewModel = viewModel
        self.rotina = rotina
        _nome = State(initialValue: rotina.nome)
        _descricao = State(initialValue: rotina.descricao)
        _frequencia = State(initialValue: rotina.frequencia)
    }

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
                Button("Salvar alterações") {
                    salvar()
                }
                .disabled(nome.isEmpty)
            }
        }
        .navigationTitle("Editar Rotina")
        .alert("Alterações salvas!", isPresented: $mostrarConfirmacao) {
            Button("OK") { dismiss() }
        }
    }

    func salvar() {
        var atualizada = rotina
        atualizada.nome = nome
        atualizada.descricao = descricao
        atualizada.frequencia = frequencia
        viewModel.atualizar(atualizada)
        mostrarConfirmacao = true
    }
}
