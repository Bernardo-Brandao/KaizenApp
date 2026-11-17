import SwiftUI
import LocalAuthentication
import Combine

@MainActor
final class Bloqueio: ObservableObject {
    static let chaveAtivo = "bloqueioFaceID"

    @Published private(set) var bloqueado: Bool
    private var pedirAoAtivar: Bool
    private var autenticando = false

    init() {
        let ativo = UserDefaults.standard.bool(forKey: Self.chaveAtivo)
        bloqueado = ativo
        pedirAoAtivar = ativo
    }

    private var ativo: Bool { UserDefaults.standard.bool(forKey: Self.chaveAtivo) }

    func bloquear() {
        guard ativo else { return }
        bloqueado = true
        pedirAoAtivar = true
    }

    func aoFicarAtivo() async {
        guard pedirAoAtivar else { return }
        pedirAoAtivar = false
        await desbloquear()
    }

    func desbloquear() async {
        guard bloqueado, !autenticando else { return }
        guard Self.disponivel else {
            bloqueado = false
            return
        }
        autenticando = true
        defer { autenticando = false }
        if await Self.autenticar(motivo: "Desbloquear o Kaizen") {
            withAnimation(.easeOut(duration: 0.2)) { bloqueado = false }
        }
    }

    static var disponivel: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static func autenticar(motivo: String) async -> Bool {
        let contexto = LAContext()
        contexto.localizedCancelTitle = "Cancelar"
        return (try? await contexto.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: motivo)) ?? false
    }

    static var nomeBiometria: String {
        let contexto = LAContext()
        _ = contexto.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch contexto.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "código"
        }
    }

    static var iconeBiometria: String {
        let contexto = LAContext()
        _ = contexto.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return contexto.biometryType == .touchID ? "touchid" : "faceid"
    }
}

struct TelaBloqueio: View {
    let aoDesbloquear: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Circle()
                .fill(Paleta.destaque)
                .frame(width: 44, height: 44)
            Text("Kaizen")
                .font(.title2.weight(.semibold))
            Spacer()
            Button(action: aoDesbloquear) {
                Label("Desbloquear", systemImage: Bloqueio.iconeBiometria)
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .tint(Paleta.destaque)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
