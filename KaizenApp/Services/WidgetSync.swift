import Foundation
import WidgetKit

// O widget lê direto do banco compartilhado; aqui só avisamos que os dados mudaram
enum WidgetSync {
    static func atualizar() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
