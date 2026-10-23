import SwiftUI

// Editar uma tarefa: nome, nota e (em rotinas diárias) os dias em que ela aparece
struct EditarTarefaView: View {
    let tarefa: Tarefa
    let mostrarDias: Bool
    var cor: Color = AppTheme.primary
    let aoSalvar: (_ nome: String, _ nota: String, _ dias: Set<Int>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var nome = ""
    @State private var nota = ""
    @State private var dias: Set<Int> = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome da tarefa", text: $nome)
                    TextField("Nota (opcional), ex.: 30 min", text: $nota)
                }
                if mostrarDias {
                    Section {
                        SeletorDiasSemana(dias: $dias, cor: cor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    } header: {
                        Text("Dias da tarefa")
                    } footer: {
                        Text(dias.isEmpty ? "Aparece todo dia." : "Aparece só em: \(DiasSemana.descricao(dias)).")
                    }
                }
            }
            .navigationTitle("Editar tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        aoSalvar(nome, nota, dias)
                        dismiss()
                    }
                    .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                nome = tarefa.nome
                nota = tarefa.nota
                dias = tarefa.diasSemana
            }
        }
    }
}
