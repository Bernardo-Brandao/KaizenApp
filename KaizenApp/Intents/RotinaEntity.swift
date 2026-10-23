import AppIntents

// A rotina como a Siri e o app Atalhos enxergam: só id e nome
struct RotinaEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Routine"
    static let defaultQuery = RotinaQuery()

    let id: Int
    let nome: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(nome)")
    }

    init(_ rotina: Rotina) {
        id = Int(rotina.id ?? 0)
        nome = rotina.nome
    }
}

// Como a Siri encontra as rotinas: por id, pelo nome falado e as sugestões (rotinas ativas)
struct RotinaQuery: EntityStringQuery {
    func entities(for identifiers: [Int]) async throws -> [RotinaEntity] {
        await rotinasAtivas().filter { identifiers.contains($0.id) }
    }

    func entities(matching texto: String) async throws -> [RotinaEntity] {
        await rotinasAtivas().filter { $0.nome.localizedStandardContains(texto) }
    }

    func suggestedEntities() async throws -> [RotinaEntity] {
        await rotinasAtivas()
    }

    @MainActor
    private func rotinasAtivas() -> [RotinaEntity] {
        RotinaDAO().listarTodas().filter { $0.ativa && $0.id != nil }.map(RotinaEntity.init)
    }
}
