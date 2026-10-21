import Foundation

// Datas no formato "yyyy-MM-dd", usado no banco para tarefas e histórico
enum DataUtil {
    // Semana começando no domingo, independente da região do aparelho
    private static let calendario: Calendar = {
        var calendario = Calendar(identifier: .gregorian)
        calendario.firstWeekday = 1
        return calendario
    }()

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendario
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func string(de data: Date) -> String {
        formatter.string(from: data)
    }

    static func data(de dia: String) -> Date? {
        formatter.date(from: dia)
    }

    static func hoje() -> String {
        string(de: Date())
    }

    // Dia anterior a uma data "yyyy-MM-dd"
    static func diaAnterior(a dia: String) -> String? {
        somar(-1, .day, a: dia)
    }

    // MARK: - Períodos (dia, semana ou mês, conforme a frequência da rotina)

    // Primeiro dia do período que contém `dia`:
    // Diária → o próprio dia; Semanal → o domingo da semana; Mensal → o dia 1 do mês
    static func inicioPeriodo(_ dia: String, frequencia: String) -> String {
        guard let data = data(de: dia) else { return dia }
        switch frequencia {
        case "Semanal":
            let diaDaSemana = calendario.component(.weekday, from: data)   // 1 = domingo
            return somar(-(diaDaSemana - 1), .day, a: dia) ?? dia
        case "Mensal":
            let componentes = calendario.dateComponents([.year, .month], from: data)
            return calendario.date(from: componentes).map(string(de:)) ?? dia
        default:
            return dia
        }
    }

    static func periodoAtual(frequencia: String) -> String {
        inicioPeriodo(hoje(), frequencia: frequencia)
    }

    // Início do período anterior a um início de período
    static func periodoAnterior(a inicio: String, frequencia: String) -> String? {
        switch frequencia {
        case "Semanal": return somar(-7, .day, a: inicio)
        case "Mensal": return somar(-1, .month, a: inicio)
        default: return somar(-1, .day, a: inicio)
        }
    }

    private static func somar(_ valor: Int, _ componente: Calendar.Component, a dia: String) -> String? {
        guard let data = data(de: dia),
              let resultado = calendario.date(byAdding: componente, value: valor, to: data)
        else { return nil }
        return string(de: resultado)
    }
}
