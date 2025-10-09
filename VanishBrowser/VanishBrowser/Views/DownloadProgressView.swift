//
//  DownloadProgressView.swift
//  VanishBrowser
//
//  Created by 簑城玄太 on 2025/10/09.
//

import SwiftUI

struct DownloadProgressView: View {
    let fileName: String
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(fileName)
                        .font(.headline)
                        .lineLimit(1)

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        .padding(.horizontal)
    }
}
