import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private static let limiteNotificacoes = 52
    private static let ocorrenciasNaoDiarias = 2

    static let categoriaLembrete = "LEMBRETE_ROTINA"
    static let acaoConcluirTudo = "CONCLUIR_TUDO"
    static let acaoAdiar = "ADIAR_1H"

    func registrarCategorias() {
        let concluir = UNNotificationAction(identifier: Self.acaoConcluirTudo, title: "Marcar como feito",
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

    func agendarLembrete(para rotina: Rotina) {
        guard let rotinaId = rotina.id else { return }

        guard rotina.ativa else {
            cancelarLembrete(para: rotina)
            return
        }

        let tarefas = TarefaDAO().listarPorRotina(rotinaId, frequencia: rotina.frequencia, dia: nil)
        let planejados = Self.planejarLembretes(
            rotina: rotina,
            tarefas: tarefas,
            aPartirDe: Date(),
            quantidadePorHorario: rotina.frequencia == "Diária" ? Self.diasDeJanela() : Self.ocorrenciasNaoDiarias,
            periodosPulados: PuloDAO().periodos(rotinaId: rotinaId)
        )

        let requests = planejados.map { lembrete -> UNNotificationRequest in
            let componentes = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: lembrete.data)
            let trigger = UNCalendarNotificationTrigger(dateMatching: componentes, repeats: false)
            let identificador = "\(Self.prefixo(rotinaId))\(DataUtil.string(de: lembrete.data))-\(lembrete.horario)"
            return UNNotificationRequest(identifier: identificador,
                                         content: Self.conteudo(rotina: rotina, horario: lembrete.horario, tarefas: lembrete.tarefas),
                                         trigger: trigger)
        }

        let hoje = DataUtil.hoje()
        let horariosResolvidos = Set(tarefas.map(\.horario).filter { !$0.isEmpty }).filter { horario in
            !tarefas.contains { $0.horario == horario && $0.aparece(em: hoje) && !$0.concluidaHoje }
        }

        Task {
            await removerPendentes(rotinaId: rotinaId)
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: horariosResolvidos.map { Self.idAdiado(rotinaId, horario: $0) })
            for request in requests {
                try? await UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func atualizarLembrete(rotinaId: Int64) {
        guard let rotina = RotinaDAO().buscar(id: rotinaId) else { return }
        agendarLembrete(para: rotina)
        agendarFimDoDia()
    }

    func reagendarTodos() {
        for rotina in RotinaDAO().listarTodas() {
            agendarLembrete(para: rotina)
        }
        agendarFimDoDia()
    }

    static let chaveFimDoDia = "fimDoDiaHorario"
    static let horarioFimDoDiaPadrao = "21:00"
    private static let prefixoFimDoDia = "fim-do-dia-"
    private static let diasFimDoDia = 3

    func agendarFimDoDia() {
        let horario = UserDefaults.standard.string(forKey: Self.chaveFimDoDia) ?? Self.horarioFimDoDiaPadrao
        let pendentes = Self.pendentesHoje()
        Task {
            await removerPendentes(prefixo: Self.prefixoFimDoDia)
            let partes = horario.split(separator: ":").compactMap { Int($0) }
            guard partes.count == 2 else { return }
            let calendario = Calendar.current
            let agora = Date()
            for dias in 0..<Self.diasFimDoDia {
                guard let dia = calendario.date(byAdding: .day, value: dias, to: agora),
                      let quando = calendario.date(bySettingHour: partes[0], minute: partes[1], second: 0, of: dia),
                      quando > agora else { continue }
                let content: UNMutableNotificationContent
                if dias == 0 {
                    guard let texto = Self.textoFimDoDia(pendentes) else { continue }
                    content = Self.conteudoFimDoDia(titulo: texto.titulo, corpo: texto.corpo)
                } else {
                    content = Self.conteudoFimDoDia(titulo: "Como foi o seu dia?",
                                                    corpo: "Se ainda faltar alguma tarefa, dá tempo de marcar.")
                }
                let componentes = calendario.dateComponents([.year, .month, .day, .hour, .minute], from: quando)
                let request = UNNotificationRequest(
                    identifier: Self.prefixoFimDoDia + DataUtil.string(de: quando),
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: componentes, repeats: false))
                try? await UNUserNotificationCenter.current().add(request)
            }
        }
    }

    static func pendentesHoje() -> [(rotina: String, faltam: Int)] {
        let hoje = DataUtil.hoje()
        let tarefaDao = TarefaDAO()
        let puloDao = PuloDAO()
        return RotinaDAO().listarTodas().compactMap { rotina in
            guard rotina.ativa, rotina.frequencia == "Diária", rotina.programada(em: hoje),
                  !puloDao.puladaAgora(rotina), let id = rotina.id else { return nil }
            let faltam = tarefaDao.listarPorRotina(id, frequencia: rotina.frequencia).filter { !$0.concluidaHoje }.count
            return faltam > 0 ? (rotina.nome, faltam) : nil
        }
    }

    static func textoFimDoDia(_ pendentes: [(rotina: String, faltam: Int)]) -> (titulo: String, corpo: String)? {
        let total = pendentes.reduce(0) { $0 + $1.faltam }
        guard total > 0 else { return nil }
        let titulo = total == 1 ? "Falta 1 tarefa hoje" : "Faltam \(total) tarefas hoje"
        let corpo = pendentes.count == 1
            ? "Na rotina \(pendentes[0].rotina). Ainda dá tempo."
            : pendentes.map { "\($0.rotina): \($0.faltam)" }.joined(separator: " · ")
        return (titulo, corpo)
    }

    private static func conteudoFimDoDia(titulo: String, corpo: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = titulo
        content.body = corpo
        content.sound = .default
        content.userInfo = ["tipo": "fimDoDia"]
        return content
    }

    func cancelarLembrete(para rotina: Rotina) {
        guard let rotinaId = rotina.id else { return }
        Task {
            await removerPendentes(rotinaId: rotinaId)
            await removerPendentes(prefixo: "adiado-rotina-\(rotinaId)")
        }
    }

    func adiarLembrete(rotinaId: Int64, horario: String, segundos: TimeInterval = 3600) {
        guard let rotina = RotinaDAO().buscar(id: rotinaId) else { return }
        let pendentes = TarefaDAO().listarPorRotina(rotinaId, frequencia: rotina.frequencia)
            .filter { $0.horario == horario && !$0.concluidaHoje }
        guard !pendentes.isEmpty else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: segundos, repeats: false)
        let request = UNNotificationRequest(identifier: Self.idAdiado(rotinaId, horario: horario),
                                            content: Self.conteudo(rotina: rotina, horario: horario, tarefas: pendentes),
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func diasDeJanela() -> Int {
        let tarefaDao = TarefaDAO()
        var horariosDiarios = 0
        var naoDiarios = 0
        for rotina in RotinaDAO().listarTodas() where rotina.ativa {
            guard let id = rotina.id else { continue }
            let horarios = Set(tarefaDao.listarPorRotina(id, frequencia: rotina.frequencia, dia: nil)
                .map(\.horario).filter { !$0.isEmpty })
            if rotina.frequencia == "Diária" {
                horariosDiarios += horarios.count
            } else {
                naoDiarios += horarios.count * ocorrenciasNaoDiarias
            }
        }
        guard horariosDiarios > 0 else { return 7 }
        return max(1, min(7, (limiteNotificacoes - naoDiarios) / horariosDiarios))
    }

    static let idResumoSemanal = "resumo-semanal"

    func agendarResumoSemanal(ativo: Bool) {
        let centro = UNUserNotificationCenter.current()
        centro.removePendingNotificationRequests(withIdentifiers: [Self.idResumoSemanal])
        guard ativo else { return }

        let content = UNMutableNotificationContent()
        content.title = "Sua semana no Kaizen"
        content.body = "Veja como foram suas rotinas nesta semana."
        content.sound = .default
        content.userInfo = ["tipo": "semana"]

        var quando = DateComponents()
        quando.weekday = 1
        quando.hour = 19
        let trigger = UNCalendarNotificationTrigger(dateMatching: quando, repeats: true)
        centro.add(UNNotificationRequest(identifier: Self.idResumoSemanal, content: content, trigger: trigger))
    }

    private static func conteudo(rotina: Rotina, horario: String, tarefas: [Tarefa]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(rotina.iconeExibido) \(rotina.nome) · \(horario)"
        content.body = tarefas.map(\.nome).joined(separator: ", ")
        content.sound = .default
        content.categoryIdentifier = categoriaLembrete
        content.threadIdentifier = "rotina-\(rotina.id ?? 0)"
        if let id = rotina.id {
            content.userInfo = ["rotinaId": id, "horario": horario, "tarefas": tarefas.compactMap(\.id)]
        }
        return content
    }

    private static func idAdiado(_ rotinaId: Int64, horario: String) -> String {
        "adiado-rotina-\(rotinaId)-\(horario)"
    }

    private func removerPendentes(rotinaId: Int64) async {
        await removerPendentes(prefixo: Self.prefixo(rotinaId))
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["rotina-\(rotinaId)", "adiado-rotina-\(rotinaId)"])
    }

    private func removerPendentes(prefixo: String) async {
        let centro = UNUserNotificationCenter.current()
        let ids = await centro.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefixo) }
        centro.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func prefixo(_ rotinaId: Int64) -> String {
        "rotina-\(rotinaId)-"
    }

    static func proximasDatas(frequencia: String, diaLembrete: Int, hora: Int, minuto: Int,
                              aPartirDe inicio: Date, quantidade: Int,
                              diasSemana: Set<Int> = [],
                              calendario: Calendar = .current) -> [Date] {
        var datas: [Date] = []
        var dia = calendario.startOfDay(for: inicio)
        for _ in 0..<400 where datas.count < quantidade {
            let componentes = calendario.dateComponents([.weekday, .day], from: dia)
            let caiNoDia: Bool
            switch frequencia {
            case "Semanal": caiNoDia = componentes.weekday == diaLembrete
            case "Mensal": caiNoDia = componentes.day == diaLembrete
            default: caiNoDia = diasSemana.isEmpty || componentes.weekday.map(diasSemana.contains) == true
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

    struct LembretePlanejado {
        let data: Date
        let horario: String
        let tarefas: [Tarefa]
    }

    static func planejarLembretes(rotina: Rotina, tarefas: [Tarefa], aPartirDe inicio: Date,
                                  quantidadePorHorario: Int, periodosPulados: Set<String> = [],
                                  hoje: String = DataUtil.hoje(),
                                  calendario: Calendar = .current) -> [LembretePlanejado] {
        let horarios = Set(tarefas.map(\.horario).filter { !$0.isEmpty }).sorted()
        var lembretes: [LembretePlanejado] = []

        for horario in horarios {
            let partes = horario.split(separator: ":")
            guard partes.count == 2, let hora = Int(partes[0]), let minuto = Int(partes[1]) else { continue }

            let datas = proximasDatas(frequencia: rotina.frequencia, diaLembrete: rotina.diaLembrete,
                                      hora: hora, minuto: minuto, aPartirDe: inicio,
                                      quantidade: quantidadePorHorario, diasSemana: rotina.diasSemana,
                                      calendario: calendario)
            for data in datas {
                let dia = DataUtil.string(de: data)
                guard !periodosPulados.contains(DataUtil.inicioPeriodo(dia, frequencia: rotina.frequencia)) else { continue }
                let periodoAtual = DataUtil.inicioPeriodo(dia, frequencia: rotina.frequencia)
                    == DataUtil.periodoAtual(frequencia: rotina.frequencia, hoje: hoje)
                let doHorario = tarefas.filter { tarefa in
                    tarefa.horario == horario
                        && (rotina.frequencia != "Diária" || tarefa.aparece(em: dia))
                        && !(periodoAtual && tarefa.concluidaHoje)
                }
                if !doHorario.isEmpty {
                    lembretes.append(LembretePlanejado(data: data, horario: horario, tarefas: doHorario))
                }
            }
        }
        return lembretes.sorted { $0.data < $1.data }
    }

    static func estaNoPeriodoAtual(_ data: Date, frequencia: String, hoje: String = DataUtil.hoje()) -> Bool {
        DataUtil.inicioPeriodo(DataUtil.string(de: data), frequencia: frequencia)
            == DataUtil.periodoAtual(frequencia: frequencia, hoje: hoje)
    }
}
