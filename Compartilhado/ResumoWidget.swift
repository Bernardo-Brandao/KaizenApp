import Foundation

// Resumo das rotinas que o app grava no App Group e o widget lê.
// Este arquivo é compilado nos dois targets (KaizenApp e KaizenWidget).
struct ResumoRotina: Codable, Identifiable {
    let id: Int64
    let nome: String
    let concluidas: Int
    let total: Int
    let corHex: String?      // cor da categoria, se tiver
    let validoAte: Date      // início do próximo período — dali em diante o progresso zera

    // Progresso considerando que o período pode ter virado desde que o app gravou
    func concluidas(em agora: Date) -> Int {
        agora >= validoAte ? 0 : concluidas
    }

    func completa(em agora: Date) -> Bool {
        total > 0 && concluidas(em: agora) == total
    }
}

enum ResumoWidget {
    static let appGroup = "group.com.bernardobrandao.projeto.KaizenApp"
    private static let chave = "resumoRotinas"

    static func salvar(_ resumos: [ResumoRotina]) {
        guard let dados = try? JSONEncoder().encode(resumos) else { return }
        UserDefaults(suiteName: appGroup)?.set(dados, forKey: chave)
    }

    static func carregar() -> [ResumoRotina] {
        guard let dados = UserDefaults(suiteName: appGroup)?.data(forKey: chave),
              let resumos = try? JSONDecoder().decode([ResumoRotina].self, from: dados)
        else { return [] }
        return resumos
    }
}
