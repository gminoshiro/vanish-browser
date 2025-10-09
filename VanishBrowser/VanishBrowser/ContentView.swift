//
//  ContentView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Vanish Browser")
                .font(.title)
            Text("準備中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
