import UIKit
import UserNotifications

// Trata os toques nas notificações de lembrete:
// - "Marcar tudo como feito" e "Adiar 1 hora" rodam sem abrir o app
// - tocar na notificação abre a tela da rotina (pelo mesmo link kaizen:// do widget)
final class NotificacaoDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificacaoDelegate()

    // Precisa ser chamado antes do app terminar de abrir, pra receber o toque que abriu o app
    func registrar() {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.registrarCategorias()
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        guard let numero = response.notification.request.content.userInfo["rotinaId"] as? NSNumber else { return }
        let rotinaId = numero.int64Value
        let acao = response.actionIdentifier

        await MainActor.run {
            switch acao {
            case NotificationManager.acaoConcluirTudo:
                ConclusaoTarefa.concluirTodas(rotinaId: rotinaId)
                WidgetSync.atualizar()
            case NotificationManager.acaoAdiar:
                NotificationManager.shared.adiarLembrete(rotinaId: rotinaId)
            case UNNotificationDefaultActionIdentifier:
                if let url = URL(string: "kaizen://rotina/\(rotinaId)") {
                    UIApplication.shared.open(url)
                }
            default:
                break
            }
        }
    }

    // Com o app aberto, o lembrete aparece como banner (o padrão do iOS é não mostrar)
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
