//
//  ContentView.swift
//  lazytable
//
//  Created by mckavan on 10.06.2026.
//

import SwiftUI
import LazyTable

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Pinned columns and rows") {
                    PinnedTableDemo()
                }
                NavigationLink("Complex: pinned groups & images") {
                    ComplexTableDemo()
                }
            }
            .navigationTitle("LazyTable demos")
        }
    }
}

#Preview {
    ContentView()
}
