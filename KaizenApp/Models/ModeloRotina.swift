import Foundation

// Rotinas prontas pra começar rápido: emoji, frequência e tarefas já preenchidos
struct ModeloRotina: Identifiable {
    let nome: String
    let icone: String
    let frequencia: String
    let descricao: String
    let tarefas: [(nome: String, nota: String)]

    var id: String { nome }

    static let todos: [ModeloRotina] = [
        ModeloRotina(nome: "Manhã produtiva", icone: "☀️", frequencia: "Diária",
                     descricao: "Começar o dia com energia e foco",
                     tarefas: [("Beber um copo de água", ""), ("Arrumar a cama", ""),
                               ("Alongar", "5 min"), ("Planejar o dia", "3 prioridades")]),
        ModeloRotina(nome: "Treino", icone: "💪", frequencia: "Diária",
                     descricao: "Movimentar o corpo todo dia",
                     tarefas: [("Aquecimento", "10 min"), ("Treino principal", "40 min"),
                               ("Alongamento", "10 min"), ("Proteína pós-treino", "")]),
        ModeloRotina(nome: "Estudos", icone: "📚", frequencia: "Diária",
                     descricao: "Um pouco de aprendizado por dia",
                     tarefas: [("Ler", "20 páginas"), ("Revisar anotações", ""),
                               ("Exercícios", "30 min"), ("Resumo do dia", "")]),
        ModeloRotina(nome: "Noite tranquila", icone: "🌙", frequencia: "Diária",
                     descricao: "Desacelerar pra dormir melhor",
                     tarefas: [("Sem telas", "30 min antes de dormir"), ("Preparar o dia seguinte", ""),
                               ("Ler um pouco", ""), ("Gratidão", "3 coisas boas do dia")]),
        ModeloRotina(nome: "Hidratação e saúde", icone: "💧", frequencia: "Diária",
                     descricao: "Os básicos que fazem diferença",
                     tarefas: [("Beber 2 litros de água", ""), ("Tomar vitaminas", ""),
                               ("Caminhar", "8 mil passos"), ("Comer uma fruta", "")]),
        ModeloRotina(nome: "Casa em ordem", icone: "🧹", frequencia: "Semanal",
                     descricao: "A faxina da semana, dividida em partes",
                     tarefas: [("Lavar roupa", ""), ("Limpar a cozinha", ""),
                               ("Aspirar a casa", ""), ("Trocar a roupa de cama", ""),
                               ("Fazer as compras", "lista no mercado")]),
        ModeloRotina(nome: "Finanças do mês", icone: "💰", frequencia: "Mensal",
                     descricao: "Fechar o mês com as contas em dia",
                     tarefas: [("Pagar as contas fixas", ""), ("Revisar os gastos", ""),
                               ("Guardar a reserva", "10% da renda"), ("Conferir a fatura do cartão", "")]),
        ModeloRotina(nome: "Leitura", icone: "📖", frequencia: "Diária",
                     descricao: "Criar o hábito de ler",
                     tarefas: [("Ler", "20 min"), ("Anotar uma ideia", "")]),
    ]
}
