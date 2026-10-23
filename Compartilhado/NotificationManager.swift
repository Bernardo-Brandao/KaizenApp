import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // Quantos lembretes avulsos ficam agendados por rotina. O iOS guarda no máximo 64
    // notificações pendentes por app, então a janela é curta e é renovada a cada abertura.
    private static let ocorrenciasAgendadas = ["Diária": 7, "Semanal": 4, "Mensal": 3]

    // Categoria do lembrete com os botões "Marcar tudo como feito" e "Adiar 1 hora".
    // As ações são tratadas no app (NotificacaoDelegate).
    static let categoriaLembrete = "LEMBRETE_ROTINA"
    static let acaoConcluirTudo = "CONCLUIR_TUDO"
    static let acaoAdiar = "ADIAR_1H"

    func registrarCategorias() {
        let concluir = UNNotificationAction(identifier: Self.acaoConcluirTudo, title: "Marcar tudo como feito",
                                            icon: UNNotificationActionIcon(systemImageName: "checkmark.circle"))
        let adiar = UNNotificationAction(identifier: Self.acaoAdiar, title: "Adiar 1 hora",
                                         icon: UNNotificationActionIcon(systemImageName: "clock.arrow.circlepath"))
        let categoria = UNNotificationCategory(identifier: Self.categoriaLembrete, actions: [concluir, adiar], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([categoria])
    }

    func solicitarPermissao() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { concedida, erro in
            if let erro = erro {
                print("Erro ao solicitar permissão de notificação: \(erro)")
            } else {
                print(concedida ? "Permissão de notificação concedida" : "Permissão de notificação negada")
            }
        }
    }

    // Agenda os próximos lembretes da rotina como notificações avulsas (uma por ocorrência),
    // pulando a do período atual se a rotina já foi completada — o "lembrete inteligente".
    func agendarLembrete(para rotina: Rotina) {
        guard let rotinaId = rotina.id else { return }

        // Rotina pausada não recebe lembrete
        guard rotina.ativa, rotina.lembreteAtivo, !rotina.horarioLembrete.isEmpty else {
            cancelarLembrete(para: rotina)
            return
        }

        let partes = rotina.horarioLembrete.split(separator: ":")
        guard partes.count == 2,
              let hora = Int(partes[0]),
              let minuto = Int(partes[1]) else { return }

        let tarefas = TarefaDAO().listarPorRotina(rotinaId, frequencia: rotina.frequencia)
        let completaNoPeriodo = !tarefas.isEmpty && tarefas.allSatisfy { $0.concluidaHoje }

        let datas = Self.proximasDatas(
            frequencia: rotina.frequencia,
            diaLembrete: rotina.diaLembrete,
            hora: hora,
            minuto: minuto,
            aPartirDe: Date(),
            quantidade: Self.ocorrenciasAgendadas[rotina.frequencia] ?? 7
        ).filter { data in
            !(completaNoPeriodo && Self.estaNoPeriodoAtual(data, frequencia: rotina.frequencia))
        }

        let requests = datas.map { data -> UNNotificationRequest in
            let content = Self.conteudo(para: rotina)

            let componentes = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: data)
            let trigger = UNCalendarNotificationTrigger(dateMatching: componentes, repeats: false)
            let identificador = "\(Self.prefixo(rotinaId))\(DataUtil.string(de: data))"
            return UNNotificationRequest(identifier: identificador, content: content, trigger: trigger)
        }

        // Remove os lembretes antigos dessa rotina antes de agendar os novos.
        // Completou no período: o lembrete adiado também não precisa mais tocar.
        Task {
            await removerPendentes(rotinaId: rotinaId)
            if completaNoPeriodo {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.idAdiado(rotinaId)])
            }
            for request in requests {
                try? await UNUserNotificationCenter.current().add(request)
            }
        }
    }

    // Reagenda a partir do id — usado quando as tarefas mudam (completar pode cancelar o lembrete do período)
    func atualizarLembrete(rotinaId: Int64) {
        guard let rotina = RotinaDAO().buscar(id: rotinaId) else { return }
        agendarLembrete(para: rotina)
    }

    // Reagenda os lembretes de todas as rotinas — renova a janela de lembretes avulsos
    // e converte os lembretes repetidos antigos
    func reagendarTodos() {
        for rotina in RotinaDAO().listarTodas() {
            agendarLembrete(para: rotina)
        }
    }

    func cancelarLembrete(para rotina: Rotina) {
        guard let rotinaId = rotina.id else { return }
        Task { await removerPendentes(rotinaId: rotinaId) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.idAdiado(rotinaId)])
    }

    // "Adiar 1 hora": um lembrete avulso daqui a `segundos`, substituindo um adiamento anterior
    func adiarLembrete(rotinaId: Int64, segundos: TimeInterval = 3600) {
        guard let rotina = RotinaDAO().buscar(id: rotinaId) else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: segundos, repeats: false)
        let request = UNNotificationRequest(identifier: Self.idAdiado(rotinaId), content: Self.conteudo(para: rotina), trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func conteudo(para rotina: Rotina) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Hora da sua rotina"
        content.body = rotina.nome
        content.sound = .default
        content.categoryIdentifier = categoriaLembrete
        if let id = rotina.id {
            content.userInfo = ["rotinaId": id]
        }
        return content
    }

    // Fora do prefixo "rotina-<id>-" de propósito: reagendar a série não apaga o adiamento
    private static func idAdiado(_ rotinaId: Int64) -> String {
        "adiado-rotina-\(rotinaId)"
    }

    private func removerPendentes(rotinaId: Int64) async {
        let centro = UNUserNotificationCenter.current()
        let ids = await centro.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.prefixo(rotinaId)) }
        // "rotina-<id>" sozinho é o lembrete repetido das versões anteriores
        centro.removePendingNotificationRequests(withIdentifiers: ids + ["rotina-\(rotinaId)"])
    }

    private static func prefixo(_ rotinaId: Int64) -> String {
        "rotina-\(rotinaId)-"
    }

    // MARK: - Cálculo das datas (sem efeitos colaterais, testável)

    // As próximas `quantidade` datas de lembrete a partir de `inicio`, no horário dado.
    // Diária: todo dia. Semanal: no dia da semana `diaLembrete` (1 = domingo). Mensal: no dia do mês `diaLembrete`.
    static func proximasDatas(frequencia: String, diaLembrete: Int, hora: Int, minuto: Int,
                              aPartirDe inicio: Date, quantidade: Int,
                              calendario: Calendar = .current) -> [Date] {
        var datas: [Date] = []
        var dia = calendario.startOfDay(for: inicio)
        // 400 dias cobre com folga 3 meses ou 4 semanas
        for _ in 0..<400 where datas.count < quantidade {
            let componentes = calendario.dateComponents([.weekday, .day], from: dia)
            let caiNoDia: Bool
            switch frequencia {
            case "Semanal": caiNoDia = componentes.weekday == diaLembrete
            case "Mensal": caiNoDia = componentes.day == diaLembrete
            default: caiNoDia = true
            }

            if caiNoDia,
               let data = calendario.date(bySettingHour: hora, minute: minuto, second: 0, of: dia),
               data > inicio {
                datas.append(data)
            }

            guard let seguinte = calendario.date(byAdding: .day, value: 1, to: dia) else { break }
            dia = seguinte
        }
        return datas
    }

    static func estaNoPeriodoAtual(_ data: Date, frequencia: String, hoje: String = DataUtil.hoje()) -> Bool {
        DataUtil.inicioPeriodo(DataUtil.string(de: data), frequencia: frequencia)
            == DataUtil.periodoAtual(frequencia: frequencia, hoje: hoje)
    }
}
