import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func solicitarPermissao() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { concedida, erro in
            if let erro = erro {
                print("Erro ao solicitar permissão de notificação: \(erro)")
            } else {
                print(concedida ? "Permissão de notificação concedida" : "Permissão de notificação negada")
            }
        }
    }

    func agendarLembrete(para rotina: Rotina) {
        guard rotina.lembreteAtivo, let rotinaId = rotina.id, !rotina.horarioLembrete.isEmpty else {
            return
        }

        let partes = rotina.horarioLembrete.split(separator: ":")
        guard partes.count == 2,
              let hora = Int(partes[0]),
              let minuto = Int(partes[1]) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Hora da sua rotina"
        content.body = rotina.nome
        content.sound = .default

        var dataComponents = DateComponents()
        dataComponents.hour = hora
        dataComponents.minute = minuto

        // repeats: true faz a notificação repetir todo dia nesse horário
        let trigger = UNCalendarNotificationTrigger(dateMatching: dataComponents, repeats: true)
        let identificador = "rotina-\(rotinaId)"

        let request = UNNotificationRequest(identifier: identificador, content: content, trigger: trigger)

        // Remove qualquer lembrete antigo dessa rotina antes de agendar o novo
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identificador])
        UNUserNotificationCenter.current().add(request)
    }

    func cancelarLembrete(para rotina: Rotina) {
        guard let rotinaId = rotina.id else { return }
        let identificador = "rotina-\(rotinaId)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identificador])
    }
}
