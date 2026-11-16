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
        // Resumo semanal abre "Sua semana"; o lembrete do fim do dia abre a tela Hoje
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
                // Lembrete de um horário: só as tarefas dele. (Lembretes antigos, sem tarefas: a rotina toda)
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

    // Com o app aberto, o lembrete aparece como banner (o padrão do iOS é não mostrar)
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
