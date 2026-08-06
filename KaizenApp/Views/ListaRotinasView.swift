//
//  ListaRotinasView.swift
//  KaizenApp
//
//  Created by Bernardo Brandão on 05/08/26.
//

import SwiftUI

struct ListaRotinasView: View {
    @StateObject var viewModel = RotinaViewModel()
    @State private var busca = ""

    var rotinasFiltradas: [Rotina] {
        busca.isEmpty ? viewModel.rotinas : viewModel.rotinas.filter {
            $0.nome.localizedCaseInsensitiveContains(busca)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(rotinasFiltradas) { rotina in
                    VStack(alignment: .leading) {
                        Text(rotina.nome).font(.headline)
                        Text(rotina.frequencia).font(.subheadline).foregroundColor(.gray)
                    }
                }
            }
            .searchable(text: $busca, prompt: "Buscar rotina")
            .navigationTitle("Minhas Rotinas")
            .onAppear { viewModel.carregar() }
        }
    }
}
