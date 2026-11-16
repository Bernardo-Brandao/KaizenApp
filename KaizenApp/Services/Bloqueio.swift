import SwiftUI
import LocalAuthentication
import Combine

// Bloqueio do app com Face ID (se falhar, o iPhone oferece o código).
// Ativado em Ajustes; o app trava ao ir para o segundo plano e pede de novo ao voltar.
@MainActor
final class Bloqueio: ObservableObject {
    static let chaveAtivo = "bloqueioFaceID"

    @Published private(set) var bloqueado: Bool
    private var pedirAoAtivar: Bool     // só pede sozinho depois de abrir ou voltar do segundo plano
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

    // O app voltou a ficar ativo: pede o Face ID uma vez (cancelar não fica pedindo de novo)
    func aoFicarAtivo() async {
        guard pedirAoAtivar else { return }
        pedirAoAtivar = false
        await desbloquear()
    }

    func desbloquear() async {
        guard bloqueado, !autenticando else { return }
        // Sem código configurado no iPhone não há como autenticar: não deixa a pessoa presa fora
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

    // MARK: - Autenticação

    static var disponivel: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static func autenticar(motivo: String) async -> Bool {
        let contexto = LAContext()
        contexto.localizedCancelTitle = "Cancelar"
        return (try? await contexto.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: motivo)) ?? false
    }

    // "Face ID", "Touch ID" ou "código", conforme o aparelho
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

// Tela por cima do app enquanto está bloqueado: o sol do ícone e o botão de desbloquear
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
