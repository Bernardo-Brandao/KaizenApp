import Foundation

enum AppGroup {
    static let id = "group.com.bernardobrandao.projeto.KaizenApp"

    static var pasta: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
    }
}
