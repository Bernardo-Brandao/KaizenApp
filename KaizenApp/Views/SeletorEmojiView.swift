import SwiftUI

// Campo do emoji nos formulários: mostra o emoji atual e abre a grade de sugestões
struct CampoEmoji: View {
    @Binding var icone: String
    @State private var mostrarSeletor = false

    var body: some View {
        Button {
            mostrarSeletor = true
        } label: {
            Text(icone.isEmpty ? Rotina.iconePadrao : icone)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Escolher emoji")
        .sheet(isPresented: $mostrarSeletor) {
            SeletorEmojiView(icone: $icone)
                .presentationDetents([.medium, .large])
        }
    }
}

// Grade de emojis sugeridos por tema, com a opção de digitar qualquer outro
struct SeletorEmojiView: View {
    @Binding var icone: String
    @Environment(\.dismiss) private var dismiss
    @State private var outro = ""

    static let grupos: [(nome: String, emojis: [String])] = [
        ("Saúde", ["🏃", "💪", "🧘", "🚴", "🏊", "🥗", "💧", "😴", "🍎", "💊"]),
        ("Mente", ["📚", "✍️", "🧠", "🎓", "📝", "🗣️", "🎧", "🧩", "🔬", "🌍"]),
        ("Trabalho", ["💼", "💻", "📈", "🗂️", "📅", "📧", "🎯", "🚀", "💡", "📊"]),
        ("Casa", ["🏠", "🧹", "🧺", "🍳", "🪴", "🛒", "🐶", "🧾", "🔧", "🛏️"]),
        ("Bem-estar", ["🌅", "☀️", "🌙", "🙏", "🎵", "🎨", "📖", "☕", "🌿", "❤️"]),
        ("Outros", ["📋", "✅", "⭐", "🔥", "⏰", "💰", "🎮", "📷", "✈️", "🎉"]),
    ]

    private let colunas = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Self.grupos, id: \.nome) { grupo in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(grupo.nome)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: colunas, spacing: 8) {
                                ForEach(grupo.emojis, id: \.self) { emoji in
                                    Button { escolher(emoji) } label: {
                                        Text(emoji)
                                            .font(.system(size: 30))
                                            .frame(maxWidth: .infinity, minHeight: 52)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(emoji == icone ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemFill))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Outro emoji")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("Digite qualquer emoji", text: $outro)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: outro) { _, novo in
                                let emoji = Rotina.normalizarIcone(novo)
                                if !emoji.isEmpty { escolher(emoji) }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Emoji da rotina")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                if !icone.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Remover") { escolher("") }
                    }
                }
            }
        }
    }

    private func escolher(_ emoji: String) {
        icone = emoji
        dismiss()
    }
}
