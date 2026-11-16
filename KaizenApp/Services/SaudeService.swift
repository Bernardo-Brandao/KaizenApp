import Foundation
import HealthKit

// Dados do app Saúde que podem preencher uma tarefa de valor sozinhos
enum MetricaSaude: String, CaseIterable, Identifiable {
    case passos, agua, exercicio, sono, mindfulness

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .passos: "Passos"
        case .agua: "Água"
        case .exercicio: "Minutos de exercício"
        case .sono: "Horas de sono"
        case .mindfulness: "Minutos de mindfulness"
        }
    }

    var unidade: String {
        switch self {
        case .passos: "passos"
        case .agua: "L"
        case .exercicio, .mindfulness: "min"
        case .sono: "h"
        }
    }

    // Meta sugerida ao escolher a métrica (a pessoa pode mudar)
    var metaSugerida: Double {
        switch self {
        case .passos: 8000
        case .agua: 2
        case .exercicio: 30
        case .sono: 7
        case .mindfulness: 10
        }
    }

    var icone: String {
        switch self {
        case .passos: "figure.walk"
        case .agua: "drop"
        case .exercicio: "flame"
        case .sono: "bed.double"
        case .mindfulness: "brain.head.profile"
        }
    }

    fileprivate var tipo: HKObjectType {
        switch self {
        case .passos: HKQuantityType(.stepCount)
        case .agua: HKQuantityType(.dietaryWater)
        case .exercicio: HKQuantityType(.appleExerciseTime)
        case .sono: HKCategoryType(.sleepAnalysis)
        case .mindfulness: HKCategoryType(.mindfulSession)
        }
    }
}

// Lê o app Saúde (só leitura) e atualiza as tarefas ligadas a uma métrica
enum SaudeService {
    private static let loja = HKHealthStore()

    static var disponivel: Bool { HKHealthStore.isHealthDataAvailable() }

    // Pede permissão de leitura (o iOS só mostra a tela na primeira vez de cada tipo)
    static func autorizar(_ metricas: [MetricaSaude] = MetricaSaude.allCases) async {
        guard disponivel else { return }
        try? await loja.requestAuthorization(toShare: [], read: Set(metricas.map(\.tipo)))
    }

    // Atualiza as tarefas ligadas ao Saúde com o valor do período atual (dia, semana ou mês).
    // Só sobe o valor: se a pessoa anotou mais à mão, o anotado fica.
    static func sincronizar() async {
        guard disponivel else { return }
        let tarefaDao = TarefaDAO()
        for rotina in RotinaDAO().listarTodas() where rotina.ativa {
            guard let rotinaId = rotina.id else { continue }
            for tarefa in tarefaDao.listarPorRotina(rotinaId, frequencia: rotina.frequencia) {
                guard let metrica = MetricaSaude(rawValue: tarefa.saude) else { continue }
                let inicio = inicioDaLeitura(metrica, frequencia: rotina.frequencia)
                guard let valor = await ler(metrica, desde: inicio),
                      Self.deveAtualizar(atual: tarefa.valorAtual, saude: valor) else { continue }
                await MainActor.run {
                    ConclusaoTarefa.registrarValor(tarefa, valor: valor, rotinaId: rotinaId)
                }
            }
        }
        await MainActor.run { WidgetSync.atualizar() }
    }

    // Arredonda pra não ficar atualizando por frações mínimas
    static func deveAtualizar(atual: Double, saude: Double) -> Bool {
        (saude * 100).rounded() > (atual * 100).rounded()
    }

    // Início do período da rotina; o sono conta a noite que terminou hoje (desde as 18h de ontem)
    static func inicioDaLeitura(_ metrica: MetricaSaude, frequencia: String, agora: Date = Date(),
                                calendario: Calendar = .current) -> Date {
        let periodo = DataUtil.periodoAtual(frequencia: frequencia, hoje: DataUtil.string(de: agora))
        let inicio = DataUtil.data(de: periodo).map { calendario.startOfDay(for: $0) } ?? calendario.startOfDay(for: agora)
        guard metrica == .sono else { return inicio }
        return calendario.date(byAdding: .hour, value: -6, to: inicio) ?? inicio
    }

    // MARK: - Leitura

    private static func ler(_ metrica: MetricaSaude, desde inicio: Date) async -> Double? {
        let predicado = HKQuery.predicateForSamples(withStart: inicio, end: Date())
        switch metrica {
        case .passos: return await soma(.stepCount, unidade: .count(), predicado)
        case .agua: return await soma(.dietaryWater, unidade: .liter(), predicado)
        case .exercicio: return await soma(.appleExerciseTime, unidade: .minute(), predicado)
        case .sono:
            // Só os trechos dormindo (não "na cama" nem acordado)
            let dormindo = HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue)
            return await duracao(.sleepAnalysis, predicado) { dormindo.contains($0.value) }.map { $0 / 3600 }
        case .mindfulness:
            return await duracao(.mindfulSession, predicado) { _ in true }.map { $0 / 60 }
        }
    }

    private static func soma(_ id: HKQuantityTypeIdentifier, unidade: HKUnit, _ predicado: NSPredicate) async -> Double? {
        let descritor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: HKQuantityType(id), predicate: predicado),
            options: .cumulativeSum)
        guard let resultado = try? await descritor.result(for: loja) else { return nil }
        return resultado.sumQuantity()?.doubleValue(for: unidade) ?? 0
    }

    // Soma das durações das amostras (em segundos), juntando trechos sobrepostos de fontes diferentes
    private static func duracao(_ id: HKCategoryTypeIdentifier, _ predicado: NSPredicate,
                                filtro: @escaping (HKCategorySample) -> Bool) async -> Double? {
        let descritor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HKCategoryType(id), predicate: predicado)],
            sortDescriptors: [SortDescriptor(\.startDate)])
        guard let amostras = try? await descritor.result(for: loja) else { return nil }
        let intervalos = amostras.filter(filtro).map { ($0.startDate, $0.endDate) }
        return Self.duracaoSemSobreposicao(intervalos)
    }

    static func duracaoSemSobreposicao(_ intervalos: [(Date, Date)]) -> Double {
        var total: TimeInterval = 0
        var atual: (Date, Date)?
        for intervalo in intervalos.sorted(by: { $0.0 < $1.0 }) {
            if let a = atual, !(a.1 < intervalo.0) {   // começa antes do fim do atual: junta (sem "<=" em Date)
                atual = (a.0, max(a.1, intervalo.1))
            } else {
                if let a = atual { total += a.1.timeIntervalSince(a.0) }
                atual = intervalo
            }
        }
        if let a = atual { total += a.1.timeIntervalSince(a.0) }
        return total
    }
}
