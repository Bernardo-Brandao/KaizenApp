import Foundation

// Datas no formato "yyyy-MM-dd", usado no banco para tarefas e histórico
enum DataUtil {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func string(de data: Date) -> String {
        formatter.string(from: data)
    }

    static func hoje() -> String {
        string(de: Date())
    }

    // Dia anterior a uma data "yyyy-MM-dd"
    static func diaAnterior(a dia: String) -> String? {
        guard let data = formatter.date(from: dia),
              let anterior = Calendar.current.date(byAdding: .day, value: -1, to: data)
        else { return nil }
        return string(de: anterior)
    }
}
