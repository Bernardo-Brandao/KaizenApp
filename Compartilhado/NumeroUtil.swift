import Foundation

// Números das tarefas de valor no formato brasileiro: mostra "1,5" e aceita "1,5" ou "1.5"
enum NumeroUtil {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    static func formatar(_ valor: Double) -> String {
        formatter.string(from: NSNumber(value: valor)) ?? String(valor)
    }

    static func ler(_ texto: String) -> Double? {
        let limpo = texto.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !limpo.isEmpty, let valor = Double(limpo), valor.isFinite else { return nil }
        return valor
    }
}
