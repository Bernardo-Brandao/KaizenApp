import UIKit
import UserNotifications

final class NotificacaoDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificacaoDelegate()

    func registrar() {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.registrarCategorias()
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        if let tipo = response.notification.request.content.userInfo["tipo"] as? String {
            let destino = tipo == "semana" ? "kaizen://semana" : "kaizen://hoje"
            await MainActor.run {
                if let url = URL(string: destino) { UIApplication.shared.open(url) }
            }
            return
        }
        guard let numero = response.notification.request.content.userInfo["rotinaId"] as? NSNumber else { return }
        let rotinaId = numero.int64Value
        let acao = response.actionIdentifier
        let info = response.notification.request.content.userInfo
        let horario = info["horario"] as? String
        let tarefaIds = (info["tarefas"] as? [NSNumber])?.map(\.int64Value)

        await MainActor.run {
            switch acao {
            case NotificationManager.acaoConcluirTudo:
                if let tarefaIds, !tarefaIds.isEmpty {
                    ConclusaoTarefa.concluir(tarefaIds: tarefaIds, rotinaId: rotinaId)
                } else {
                    ConclusaoTarefa.concluirTodas(rotinaId: rotinaId)
                }
                WidgetSync.atualizar()
            case NotificationManager.acaoAdiar:
                if let horario {
                    NotificationManager.shared.adiarLembrete(rotinaId: rotinaId, horario: horario)
                }
            case UNNotificationDefaultActionIdentifier:
                if let url = URL(string: "kaizen://rotina/\(rotinaId)") {
                    UIApplication.shared.open(url)
                }
            default:
                break
            }
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
