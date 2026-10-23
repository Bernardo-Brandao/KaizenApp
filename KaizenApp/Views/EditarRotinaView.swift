import SwiftUI

struct EditarRotinaView: View {
    @ObservedObject var viewModel: RotinaViewModel
    @Environment(\.dismiss) var dismiss

    let rotina: Rotina

    @State private var nome: String
    @State private var descricao: String
    @State private var frequencia: String
    @State private var lembreteAtivo: Bool
    @State private var horarioLembrete: Date
    @State private var categoriaId: Int64?
    @State private var diaLembrete: Int
    @State private var icone: String
    @State private var mostrarConfirmacao = false

    let opcoesFrequencia = ["Diária", "Semanal", "Mensal"]

    init(viewModel: RotinaViewModel, rotina: Rotina) {
        self.viewModel = viewModel
        self.rotina = rotina
        _nome = State(initialValue: rotina.nome)
        _descricao = State(initialValue: rotina.descricao)
        _frequencia = State(initialValue: rotina.frequencia)
        _lembreteAtivo = State(initialValue: rotina.lembreteAtivo)
        _categoriaId = State(initialValue: rotina.categoriaId)
        _diaLembrete = State(initialValue: rotina.diaLembrete)
        _icone = State(initialValue: rotina.icone)

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let data = formatter.date(from: rotina.horarioLembrete) {
            _horarioLembrete = State(initialValue: data)
        } else {
            _horarioLembrete = State(initialValue: Date())
        }
    }

    var body: some View {
        Form {
            Section("Informações da rotina") {
                HStack {
                    CampoEmoji(icone: $icone)
                    TextField("Nome da rotina", text: $nome)
                }
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
        atualizada.lembreteAtivo = lembreteAtivo
        atualizada.categoriaId = categoriaId
        atualizada.diaLembrete = diaLembrete
        atualizada.icone = icone

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        atualizada.horarioLembrete = lembreteAtivo ? formatter.string(from: horarioLembrete) : ""

        viewModel.atualizar(atualizada)
        mostrarConfirmacao = true
    }
}
