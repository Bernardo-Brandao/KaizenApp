import AppIntents
import Foundation
import WidgetKit

enum WidgetSync {
    static func atualizar() {
        WidgetCenter.shared.reloadAllTimelines()
        KaizenShortcuts.updateAppShortcutParameters()
    }
}
