import Foundation

// Área compartilhada entre o app e o widget (banco de dados fica aqui)
enum AppGroup {
    static let id = "group.com.bernardobrandao.projeto.KaizenApp"

    static var pasta: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
    }
}
