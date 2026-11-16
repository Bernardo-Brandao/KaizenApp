import SwiftUI

// Formulário pra editar uma rotina já criada
struct EditarRotinaView: View {
    @ObservedObject var viewModel: RotinaViewModel
    @Environment(\.dismiss) var dismiss

    let rotina: Rotina

    @State private var nome: String
    @State private var descricao: String
    @State private var frequencia: String
    @State private var categoriaId: Int64?
    @State private var diaLembrete: Int
    @State private var icone: String
    @State private var diasSemana: Set<Int>
    @State private var mostrarConfirmacao = false

    let opcoesFrequencia = ["Diária", "Semanal", "Mensal"]

    init(viewModel: RotinaViewModel, rotina: Rotina) {
        self.viewModel = viewModel
        self.rotina = rotina
        _nome = State(initialValue: rotina.nome)
        _descricao = State(initialValue: rotina.descricao)
        _frequencia = State(initialValue: rotina.frequencia)
        _categoriaId = State(initialValue: rotina.categoriaId)
        _diaLembrete = State(initialValue: rotina.diaLembrete)
        _icone = State(initialValue: rotina.icone)
        _diasSemana = State(initialValue: rotina.diasSemana)
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

            // Diária: em quais dias a rotina vale (nos outros, folga)
            if frequencia == "Diária" {
                Section {
                    SeletorDiasSemana(dias: $diasSemana)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                } header: {
                    Text("Repetir em")
                } footer: {
                    Text(diasSemana.isEmpty
                         ? "Todo dia."
                         : "\(DiasSemana.descricao(diasSemana)). Nos outros dias a rotina fica de folga: não conta, não quebra a sequência e não tem lembrete.")
                }
            }

            LembreteSection(frequencia: frequencia, dia: $diaLembrete)

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
        atualizada.lembreteAtivo = false   // os horários dos lembretes ficam em cada tarefa
        atualizada.categoriaId = categoriaId
        atualizada.diaLembrete = diaLembrete
        atualizada.icone = icone
        atualizada.diasSemana = frequencia == "Diária" ? diasSemana : []
        atualizada.horarioLembrete = ""

        viewModel.atualizar(atualizada)
        mostrarConfirmacao = true
    }
}
