import SwiftUI

// Editar uma tarefa: nome, nota e (em rotinas diárias) os dias em que ela aparece
struct EditarTarefaView: View {
    let tarefa: Tarefa
    let mostrarDias: Bool
    var frequencia = "Diária"
    var cor: Color = Paleta.destaque
    let aoSalvar: (_ nome: String, _ nota: String, _ dias: Set<Int>, _ horario: String,
                   _ tipo: String, _ unidade: String, _ meta: Double?, _ saude: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var nome = ""
    @State private var nota = ""
    @State private var dias: Set<Int> = []
    @State private var horario = ""
    @State private var tipo = "check"
    @State private var unidade = ""
    @State private var meta = ""
    @State private var saude = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome da tarefa", text: $nome)
                    TextField("Nota (opcional), ex.: 30 min", text: $nota)
                }
                Section {
                    CampoTipoTarefa(tipo: $tipo, unidade: $unidade, meta: $meta, saude: $saude, frequencia: frequencia)
                } header: {
                    Text("Tipo")
                } footer: {
                    Text(CampoTipoTarefa.explicacao(tipo, frequencia: frequencia))
                }
                Section {
                    CampoHorario(horario: $horario)
                } footer: {
                    Text("Tarefas da rotina no mesmo horário chegam juntas numa notificação só. Se a tarefa já estiver feita, o lembrete não toca.")
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
                        aoSalvar(nome, nota, dias, horario, tipo, unidade, NumeroUtil.ler(meta), tipo == "valor" ? saude : "")
                        dismiss()
                    }
                    .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                nome = tarefa.nome
                nota = tarefa.nota
                dias = tarefa.diasSemana
                horario = tarefa.horario
                tipo = tarefa.tipo
                unidade = tarefa.unidade
                meta = tarefa.meta.map(NumeroUtil.formatar) ?? ""
                saude = tarefa.saude
            }
        }
    }
}
