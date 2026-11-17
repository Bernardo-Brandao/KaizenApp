import Foundation

enum DataUtil {
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

    static func diaDaSemana(_ dia: String) -> Int? {
        data(de: dia).map { calendario.component(.weekday, from: $0) }
    }

    static func hoje() -> String {
        string(de: Date())
    }

    static func diaAnterior(a dia: String) -> String? {
        somar(-1, .day, a: dia)
    }

    static func inicioPeriodo(_ dia: String, frequencia: String) -> String {
        guard let data = data(de: dia) else { return dia }
        switch frequencia {
        case "Semanal":
            let diaDaSemana = calendario.component(.weekday, from: data)
            return somar(-(diaDaSemana - 1), .day, a: dia) ?? dia
        case "Mensal":
            let componentes = calendario.dateComponents([.year, .month], from: data)
            return calendario.date(from: componentes).map(string(de:)) ?? dia
        default:
            return dia
        }
    }

    static func periodoAtual(frequencia: String, hoje dia: String = hoje()) -> String {
        inicioPeriodo(dia, frequencia: frequencia)
    }

    static func concluidaNoPeriodoAtual(_ dataConclusao: String, frequencia: String, hoje dia: String = hoje()) -> Bool {
        !dataConclusao.isEmpty
            && inicioPeriodo(dataConclusao, frequencia: frequencia) == periodoAtual(frequencia: frequencia, hoje: dia)
    }

    static func periodoAnterior(a inicio: String, frequencia: String) -> String? {
        switch frequencia {
        case "Semanal": return somar(-7, .day, a: inicio)
        case "Mensal": return somar(-1, .month, a: inicio)
        default: return somar(-1, .day, a: inicio)
        }
    }

    static func inicioProximoPeriodo(frequencia: String, hoje dia: String = hoje()) -> Date? {
        let atual = periodoAtual(frequencia: frequencia, hoje: dia)
        let proximo: String?
        switch frequencia {
        case "Semanal": proximo = somar(7, .day, a: atual)
        case "Mensal": proximo = somar(1, .month, a: atual)
        default: proximo = somar(1, .day, a: atual)
        }
        return proximo.flatMap(data(de:))
    }

    private static func somar(_ valor: Int, _ componente: Calendar.Component, a dia: String) -> String? {
        guard let data = data(de: dia),
              let resultado = calendario.date(byAdding: componente, value: valor, to: data)
        else { return nil }
        return string(de: resultado)
    }
}
